#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Utilities;

codeunit 10147 "E-Invoice Object Factory"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Codeunit is deprecated, reference barcode libraries directly.';
    ObsoleteTag = '22.0';

    procedure GetBarCodeProvider(var IBarCodeProvider: DotNet IBarcodeProvider)
    var
        QRCodeProvider: DotNet QRCodeProvider;
    begin
        if IsNull(IBarCodeProvider) then
            IBarCodeProvider := QRCodeProvider.QRCodeProvider();
    end;

    procedure GetBarCodeBlob(QRCodeInput: Text; var TempBLOB: Codeunit "Temp Blob")
    var
        IBarCodeProvider: DotNet IBarcodeProvider;
        BlobOutStr: OutStream;
    begin
        GetBarCodeProvider(IBarCodeProvider);

        TempBLOB.CreateOutStream(BlobOutStr);
        IBarCodeProvider.GetBarcodeStream(QRCodeInput, BlobOutStr);
    end;

}
#endif