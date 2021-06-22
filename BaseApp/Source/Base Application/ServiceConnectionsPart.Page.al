page 1278 "Service Connections Part"
{
    Caption = 'Service Connections Part';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Connection";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control8)
            {
                ShowCaption = false;
                repeater(Group)
                {
                    field(Name; Name)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the service. The description is based on the name of the setup page that opens when you choose the Setup.';
                    }
                    field("Host Name"; "Host Name")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the name of the web service. This is typically a URL.';
                    }
                    field(Status; Status)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the service is enabled or disabled.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                Enabled = SetupActive;
                Image = Setup;
                ShortCutKey = 'Return';
                ToolTip = 'Get a connection to a service up and running or manage an connection that is already working.';

                trigger OnAction()
                begin
                    CallSetup;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetupActive :=
          ("Page ID" <> 0);
    end;

    trigger OnOpenPage()
    begin
        OnRegisterServiceConnection(Rec);
    end;

    var
        SetupActive: Boolean;

    local procedure CallSetup()
    var
        RecordRefVariant: Variant;
        RecordRef: RecordRef;
    begin
        if not SetupActive then
            exit;
        RecordRef.Get("Record ID");
        RecordRefVariant := RecordRef;
        PAGE.RunModal("Page ID", RecordRefVariant);
        Delete;
        OnRegisterServiceConnection(Rec);
        if Get(xRec."No.") then;
        CurrPage.Update(false);
    end;
}

