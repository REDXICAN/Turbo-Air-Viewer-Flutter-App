// supabase/functions/send-email/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EmailRequest {
  to: string
  cc?: string
  subject: string
  quoteData: {
    quoteNumber: string
    clientName: string
    items: Array<{
      sku: string
      productType: string
      quantity: number
      unitPrice: number
      totalPrice: number
    }>
    subtotal: number
    taxRate: number
    taxAmount: number
    totalAmount: number
  }
  additionalMessage?: string
  attachPdf?: boolean
  attachExcel?: boolean
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Verify authentication
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    const emailData: EmailRequest = await req.json()
    
    // Generate HTML email body
    const htmlBody = generateEmailHtml(emailData)
    
    // Send email using SMTP (you can use any email service here)
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Turbo Air <turboairquotes@gmail.com>',
        to: [emailData.to],
        cc: emailData.cc ? [emailData.cc] : undefined,
        subject: emailData.subject,
        html: htmlBody,
        attachments: await generateAttachments(emailData),
      }),
    })

    if (!response.ok) {
      throw new Error('Failed to send email')
    }

    const result = await response.json()

    return new Response(
      JSON.stringify({ success: true, messageId: result.id }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

function generateEmailHtml(data: EmailRequest): string {
  const { quoteData, additionalMessage } = data
  
  const itemsHtml = quoteData.items.map(item => `
    <tr style="border-bottom: 1px solid #ddd;">
      <td style="padding: 8px; text-align: left;">${item.sku}</td>
      <td style="padding: 8px; text-align: left;">${item.productType}</td>
      <td style="padding: 8px; text-align: center;">${item.quantity}</td>
      <td style="padding: 8px; text-align: right;">$${item.unitPrice.toFixed(2)}</td>
      <td style="padding: 8px; text-align: right; font-weight: bold;">$${item.totalPrice.toFixed(2)}</td>
    </tr>
  `).join('')
  
  const additionalHtml = additionalMessage ? `
    <div style="margin: 20px 0; padding: 15px; background-color: #f8f9fa; border-left: 4px solid #20429C;">
      <h3 style="margin-top: 0; color: #20429C;">Additional Message:</h3>
      <p style="margin-bottom: 0; white-space: pre-wrap;">${additionalMessage}</p>
    </div>
  ` : ''
  
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
  `
}

async function generateAttachments(data: EmailRequest): Promise<any[]> {
  const attachments = []
  
  // Generate PDF attachment if requested
  if (data.attachPdf) {
    // Implementation would generate PDF here
    // For now, returning empty array
  }
  
  // Generate Excel attachment if requested
  if (data.attachExcel) {
    // Implementation would generate Excel here
    // For now, returning empty array
  }
  
  return attachments
}