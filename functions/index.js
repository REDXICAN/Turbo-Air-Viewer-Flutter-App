// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure email transporter (using Gmail as example)
// For production, use SendGrid, Mailgun, or other professional service
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.password,
  },
});

// Alternative: SendGrid configuration
/*
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(functions.config().sendgrid.key);
*/

exports.sendEmail = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to send emails'
    );
  }

  const {
    to,
    cc,
    subject,
    quoteData,
    additionalMessage,
    attachPdf,
    attachExcel,
  } = data;

  try {
    // Generate HTML email content
    const htmlContent = generateEmailHtml(quoteData, additionalMessage);

    // Prepare email options
    const mailOptions = {
      from: 'Turbo Air <turboairquotes@gmail.com>',
      to: to,
      cc: cc,
      subject: subject,
      html: htmlContent,
    };

    // Add attachments if requested
    if (attachPdf || attachExcel) {
      mailOptions.attachments = [];
      
      if (attachPdf) {
        // Generate PDF attachment
        const pdfBuffer = await generateQuotePDF(quoteData);
        mailOptions.attachments.push({
          filename: `quote_${quoteData.quoteNumber}.pdf`,
          content: pdfBuffer,
        });
      }
      
      if (attachExcel) {
        // Generate Excel attachment
        const excelBuffer = await generateQuoteExcel(quoteData);
        mailOptions.attachments.push({
          filename: `quote_${quoteData.quoteNumber}.xlsx`,
          content: excelBuffer,
        });
      }
    }

    // Send email
    await transporter.sendMail(mailOptions);

    // Alternative: Using SendGrid
    /*
    const msg = {
      to: to,
      cc: cc,
      from: 'turboairquotes@gmail.com',
      subject: subject,
      html: htmlContent,
      attachments: attachments,
    };
    await sgMail.send(msg);
    */

    return { success: true, message: 'Email sent successfully' };
    
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send email',
      error.message
    );
  }
});

function generateEmailHtml(quoteData, additionalMessage) {
  const itemsHtml = quoteData.items.map(item => `
    <tr style="border-bottom: 1px solid #ddd;">
      <td style="padding: 8px; text-align: left;">${item.sku}</td>
      <td style="padding: 8px; text-align: left;">${item.productType}</td>
      <td style="padding: 8px; text-align: center;">${item.quantity}</td>
      <td style="padding: 8px; text-align: right;">$${item.unitPrice.toFixed(2)}</td>
      <td style="padding: 8px; text-align: right; font-weight: bold;">$${item.totalPrice.toFixed(2)}</td>
    </tr>
  `).join('');
  
  const additionalHtml = additionalMessage ? `
    <div style="margin: 20px 0; padding: 15px; background-color: #f8f9fa; border-left: 4px solid #20429C;">
      <h3 style="margin-top: 0; color: #20429C;">Additional Message:</h3>
      <p style="margin-bottom: 0; white-space: pre-wrap;">${additionalMessage}</p>
    </div>
  ` : '';
  
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background-color: #20429C; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .quote-info { background-color: #f8f9fa; padding: 15px; margin: 20px 0; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background-color: #20429C; color: white; padding: 12px; text-align: left; }
        .totals { background-color: #f8f9fa; padding: 15px; margin: 20px 0; }
        .total-row { font-weight: bold; font-size: 1.1em; }
        .footer { background-color: #f1f1f1; padding: 20px; text-align: center; color: #666; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>TURBO AIR EQUIPMENT</h1>
        <h2>Equipment Quote</h2>
      </div>
      
      <div class="content">
        <div class="quote-info">
          <h3>Quote Information</h3>
          <p><strong>Quote Number:</strong> ${quoteData.quoteNumber}</p>
          <p><strong>Date:</strong> ${new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
          <p><strong>Client:</strong> ${quoteData.clientName}</p>
        </div>
        
        ${additionalHtml}
        
        <h3>Equipment List</h3>
        <table>
          <thead>
            <tr>
              <th>SKU</th>
              <th>Description</th>
              <th style="text-align: center;">Qty</th>
              <th style="text-align: right;">Unit Price</th>
              <th style="text-align: right;">Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
        </table>
        
        <div class="totals">
          <table style="width: 100%; margin: 0;">
            <tr>
              <td style="text-align: right; padding: 5px;"><strong>Subtotal:</strong></td>
              <td style="text-align: right; padding: 5px; width: 120px;"><strong>$${quoteData.subtotal.toFixed(2)}</strong></td>
            </tr>
            <tr>
              <td style="text-align: right; padding: 5px;"><strong>Tax (${quoteData.taxRate.toFixed(1)}%):</strong></td>
              <td style="text-align: right; padding: 5px;"><strong>$${quoteData.taxAmount.toFixed(2)}</strong></td>
            </tr>
            <tr class="total-row" style="border-top: 2px solid #20429C;">
              <td style="text-align: right; padding: 10px 5px 5px 5px;"><strong>TOTAL:</strong></td>
              <td style="text-align: right; padding: 10px 5px 5px 5px; font-size: 1.2em;"><strong>$${quoteData.totalAmount.toFixed(2)}</strong></td>
            </tr>
          </table>
        </div>
      </div>
      
      <div class="footer">
        <p><strong>Thank you for choosing Turbo Air Equipment!</strong></p>
        <p>This quote is valid for 30 days from the date of issue.</p>
        <p>For questions about this quote, please contact us at turboairquotes@gmail.com</p>
      </div>
    </body>
    </html>
  `;
}

// Placeholder functions for PDF and Excel generation
async function generateQuotePDF(quoteData) {
  // Implement PDF generation using packages like pdfkit or puppeteer
  // Return buffer
  return Buffer.from('PDF content');
}

async function generateQuoteExcel(quoteData) {
  // Implement Excel generation using packages like exceljs
  // Return buffer
  return Buffer.from('Excel content');
}