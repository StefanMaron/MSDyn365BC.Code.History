dotnet
{
    assembly("Microsoft.Dynamics.Nav.Ncl")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.Runtime.DesignedQuery.AL.DqImportExportResults"; "DqImportExportResults")
        {
        }

        type("Microsoft.Dynamics.Nav.Runtime.DesignedQuery.AL.DqImportExportResult"; "DqImportExportResult")
        {
        }

        type("Microsoft.Dynamics.Nav.Runtime.DesignedQuery.AL.DqImporter"; "DqImporter")
        {
        }

        type("Microsoft.Dynamics.Nav.Runtime.DesignedQuery.AL.DqExportArgs"; "DqExportArgs")
        {
        }

        type("Microsoft.Dynamics.Nav.Runtime.DesignedQuery.AL.DqExporter"; "DqExporter")
        {
        }

        type("Microsoft.Dynamics.Nav.Runtime.AL.ALCloudMigration"; "ALCloudMigration")
        {
        }

        type("Microsoft.Dynamics.Nav.Runtime.LastError"; "LastError")
        {
        }

        type("Microsoft.Dynamics.Nav.Runtime.VSCodeRequestHelper"; "VSCodeRequestHelper")
        {
        }
    }
    assembly("Microsoft.Dynamics.Nav.NavUserAccount")
    {

        type("Microsoft.Dynamics.Nav.NavUserAccount.NavUserAccountHelper"; "NavUserAccountHelper")
        {
        }
    }
    assembly(Microsoft.Dynamics.Nav.MX)
    {
        type(Microsoft.Dynamics.QRCode.ErrorCorrectionLevel; "QRCode Error Correction Level") { }
        type(Microsoft.Dynamics.Nav.MX.BarcodeProviders.IBarcodeProvider; "IBarcode Provider") { }
        type(Microsoft.Dynamics.Nav.MX.BarcodeProviders.QRCodeProvider; "QRCode Provider") { }
    }
    assembly(Microsoft.AspNetCore.StaticFiles)
    {
        type(Microsoft.AspNetCore.StaticFiles.FileExtensionContentTypeProvider; FileExtensionContentTypeProvider) { }
    }
}
