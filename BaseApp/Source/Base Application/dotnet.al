dotnet
{
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

    assembly("Microsoft.Dynamics.Nav.Client.PingPong")
    {
        type("Microsoft.Dynamics.Nav.Client.PingPong.PingPongAddIn"; "Microsoft.Dynamics.Nav.Client.PingPong")
        {
            IsControlAddIn = true;
        }
    }

    assembly("Microsoft.Dynamics.Nav.Client.TimelineVisualization")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.Client.TimelineVisualization.InteractiveTimelineVisualizationAddIn"; "Microsoft.Dynamics.Nav.Client.TimelineVisualization")
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
}
