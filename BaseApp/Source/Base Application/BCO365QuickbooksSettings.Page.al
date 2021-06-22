page 2375 "BC O365 Quickbooks Settings"
{
    Caption = ' ';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field(SyncWithQbo; SyncWithQboLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;
                Visible = QBOVisible;

                trigger OnDrillDown()
                begin
                    OnQuickBooksOnlineSyncClicked;
                end;
            }
            field(SyncWithQbd; SyncWithQbdLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;
                Visible = QBDVisible;

                trigger OnDrillDown()
                begin
                    OnQuickBooksDesktopSyncClicked;
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        SetVisibility;
    end;

    var
        SyncWithQboLbl: Label 'For QuickBooks Online, log in and allow Invoicing to access your QuickBooks.';
        SyncWithQbdLbl: Label 'For QuickBooks Desktop, launch the setup guide.';
        O365SalesManagement: Codeunit "O365 Sales Management";
        QBDVisible: Boolean;
        QBOVisible: Boolean;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnQuickBooksOnlineSyncClicked()
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnQuickBooksDesktopSyncClicked()
    begin
    end;

    local procedure SetVisibility()
    begin
        O365SalesManagement.GetQboQbdVisibility(QBOVisible, QBDVisible);
    end;
}

