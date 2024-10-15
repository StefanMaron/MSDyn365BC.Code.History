dotnet
{
    assembly("Microsoft.Dynamics.Nav.ClientExtensions")
    {
        type("Microsoft.Dynamics.Nav.Client.Capabilities.CameraBarcodeScannerProvider"; "CameraBarcodeScannerProvider")
        {
        }

        type("Microsoft.Dynamics.Nav.Client.Capabilities.BarcodeScannerProvider"; "BarcodeScannerProvider")
        {
        }
    }
    assembly("Microsoft.Dynamics.Nav.Client.RoleCenterSelector")
    {
        type("Microsoft.Dynamics.Nav.Client.RoleCenterSelector.IRoleCenterSelector"; "Microsoft.Dynamics.Nav.Client.RoleCenterSelector")
        {
            IsControlAddIn = true;
        }
    }

    assembly("Microsoft.Dynamics.Nav.Client.PowerBIManagement")
    {
        type("Microsoft.Dynamics.Nav.Client.PowerBIManagement.PowerBIManagement"; "Microsoft.Dynamics.Nav.Client.PowerBIManagement")
        {
            IsControlAddIn = true;
        }
    }

    assembly("Microsoft.Dynamics.Nav.Client.OAuthIntegration")
    {
        type("Microsoft.Dynamics.Nav.Client.OAuthIntegration.OAuthIntegration"; "Microsoft.Dynamics.Nav.Client.OAuthIntegration")
        {
            IsControlAddIn = true;
        }
    }

    assembly("Microsoft.Dynamics.Nav.Client.WelcomeWizard")
    {
        type("Microsoft.Dynamics.Nav.Client.WelcomeWizard.IWelcomeWizard"; "Microsoft.Dynamics.Nav.Client.WelcomeWizard")
        {
            IsControlAddIn = true;
        }
    }

    assembly("Microsoft.Dynamics.Nav.Client.FlowIntegration")
    {
        type("Microsoft.Dynamics.Nav.Client.FlowIntegration.IFlowIntegration"; "Microsoft.Dynamics.Nav.Client.FlowIntegration")
        {
            IsControlAddIn = true;
        }
    }

    assembly("Microsoft.Dynamics.Nav.Client.BusinessChart")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.Client.BusinessChart.BusinessChartAddIn"; "Microsoft.Dynamics.Nav.Client.BusinessChart")
        {
            IsControlAddIn = true;
        }
    }

    assembly("Microsoft.Dynamics.Nav.Client.WebPageViewer")
    {
        type("Microsoft.Dynamics.Nav.Client.WebPageViewer.IWebPageViewer"; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
        {
            IsControlAddIn = true;
        }
    }

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
