package com.example.coloringbook.services

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.pdf.PdfDocument
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager

object PrintService {

    fun printBitmap(context: Context, bitmap: Bitmap, title: String): Boolean {
        val printManager = context.getSystemService(Context.PRINT_SERVICE) as? PrintManager
            ?: return false

        val isLandscape = bitmap.width > bitmap.height

        printManager.print(
            title,
            object : PrintDocumentAdapter() {
                override fun onLayout(
                    oldAttributes: PrintAttributes?,
                    newAttributes: PrintAttributes,
                    cancellationSignal: CancellationSignal?,
                    callback: LayoutResultCallback,
                    extras: Bundle?
                ) {
                    if (cancellationSignal?.isCanceled == true) {
                        callback.onLayoutCancelled()
                        return
                    }
                    val info = PrintDocumentInfo.Builder(title)
                        .setContentType(PrintDocumentInfo.CONTENT_TYPE_PHOTO)
                        .setPageCount(1)
                        .build()
                    callback.onLayoutFinished(info, true)
                }

                override fun onWrite(
                    pages: Array<out PageRange>,
                    destination: ParcelFileDescriptor,
                    cancellationSignal: CancellationSignal?,
                    callback: WriteResultCallback
                ) {
                    if (cancellationSignal?.isCanceled == true) {
                        callback.onWriteCancelled()
                        return
                    }
                    val pdfDocument = PdfDocument()
                    val pageInfo = PdfDocument.PageInfo.Builder(
                        if (isLandscape) 792 else 612,
                        if (isLandscape) 612 else 792,
                        1
                    ).create()
                    val page = pdfDocument.startPage(pageInfo)
                    drawBitmapOnPage(page.canvas, bitmap, pageInfo.pageWidth, pageInfo.pageHeight)
                    pdfDocument.finishPage(page)
                    try {
                        pdfDocument.writeTo(ParcelFileDescriptor.AutoCloseOutputStream(destination))
                        callback.onWriteFinished(arrayOf(PageRange.ALL_PAGES))
                    } catch (e: Exception) {
                        callback.onWriteFailed(e.message)
                    } finally {
                        pdfDocument.close()
                    }
                }
            },
            PrintAttributes.Builder()
                .setMediaSize(
                    if (isLandscape) PrintAttributes.MediaSize.NA_LETTER.asLandscape()
                    else PrintAttributes.MediaSize.NA_LETTER
                )
                .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
                .build()
        )
        return true
    }

    private fun drawBitmapOnPage(canvas: Canvas, bitmap: Bitmap, pageW: Int, pageH: Int) {
        val margin = 36f
        val availW = pageW - 2 * margin
        val availH = pageH - 2 * margin
        val scale = minOf(availW / bitmap.width, availH / bitmap.height)
        val drawW = bitmap.width * scale
        val drawH = bitmap.height * scale
        val left = margin + (availW - drawW) / 2
        val top = margin + (availH - drawH) / 2
        canvas.drawColor(Color.WHITE)
        canvas.drawBitmap(bitmap, null, RectF(left, top, left + drawW, top + drawH), Paint(Paint.FILTER_BITMAP_FLAG))
    }
}
