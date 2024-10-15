#if not CLEAN23
namespace System.Integration.PowerBI;

page 6316 "Content Pack Setup Wizard"
{
    // // Wizard page to walk the user through connecting PBI content packs to their NAV data.
    // // This page is the wizard frame and text, all actual fields are in the page part, 6317.

    Caption = 'Connector Setup Information';
    PageType = NavigatePage;
    ObsoleteState = Pending;
    ObsoleteReason = 'Instead, follow the Business Central documentation page "Building Power BI Reports to Display Dynamics 365 Business Central Data" available at https://learn.microsoft.com/en-gb/dynamics365/business-central/across-how-use-financials-data-source-powerbi';
    ObsoleteTag = '23.0';

    layout
    {
        area(content)
        {
            label("Connectors enable Business Central to communicate with Power BI, PowerApps, and Microsoft Flow.")
            {
                ApplicationArea = All;
                Caption = 'Connectors enable Business Central to communicate with Microsoft Power BI, Power Apps, and Power Automate.';
            }
            label(Control6)
            {
                ApplicationArea = All;
                Caption = 'This page provides the required information you will need to connect to these applications. Simply copy and paste this information into the Microsoft Power BI, Power Apps, or Power Automate connector when prompted.';
            }
            label(Control7)
            {
                ApplicationArea = All;
                Caption = 'Depending on your configuration, you will either connect using the password for the user name displayed below, or with the web service access key displayed below.';
            }
            part(ContentPackSetup; "Content Pack Setup Part")
            {
                ApplicationArea = All;
                Caption = ' ', Locked = true;
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }
}

#endif