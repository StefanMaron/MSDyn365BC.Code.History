page 1279 "Service Connections"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Service Connections';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Service Connection";
    SourceTableTemporary = true;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the service. The description is based on the name of the setup page that opens when you choose the Setup.';
                }
                field("Host Name"; Rec."Host Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the web service. This is typically a URL.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleExpression;
                    ToolTip = 'Specifies if the service is enabled or disabled.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                Enabled = SetupActive;
                Image = Setup;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Get a connection to a service up and running or manage an connection that is already working.';

                trigger OnAction()
                begin
                    CallSetup();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Setup_Promoted; Setup)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        RefreshPressed: Boolean;
    begin
        RefreshPressed := CurrRecordNo = "No.";
        if RefreshPressed then
            Refresh()
        else
            CurrRecordNo := "No.";
        SetupActive := "Page ID" <> 0;
        SetStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    trigger OnInit()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        CRMIntegrationManagement.RegisterAssistedSetup();
        CDSIntegrationMgt.RegisterAssistedSetup();
    end;

    trigger OnOpenPage()
    begin
        ReloadServiceConnections();
    end;

    var
        SetupActive: Boolean;
        StyleExpression: Text;
        CurrRecordNo: Text;

    local procedure CallSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        RecordRef: RecordRef;
        RecordRefVariant: Variant;
        DummyRecordID: RecordID;
        CurrentRecordId: RecordID;
    begin
        if not SetupActive then
            exit;
        if ((Status = Status::Error) or (Status = Status::Disabled)) and
           ("Assisted Setup Page ID" > 0) and
           (GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, "Assisted Setup Page ID"))
        then
            GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, "Assisted Setup Page ID")
        else begin
            CurrentRecordId := "Record ID";

            if CurrentRecordId = DummyRecordID then
                Page.RunModal("Page ID")
            else
                if not RecordRef.Get("Record ID") then
                    Page.RunModal("Page ID")
                else begin
                    RecordRefVariant := RecordRef;
                    Page.RunModal("Page ID", RecordRefVariant);
                end;
        end;
        ReloadServiceConnections();
        if Get(xRec."No.") then;
        CurrPage.Update(false);
    end;

    local procedure SetStyle()
    begin
        case Status of
            Status::Disabled:
                StyleExpression := 'Standard';
            Status::Connected, Status::Enabled:
                StyleExpression := 'Favorable';
            Status::Error:
                StyleExpression := 'Unfavorable';
        end
    end;

    local procedure Refresh()
    begin
        ReloadServiceConnections();
        CurrRecordNo := Format(CreateGuid());
        if Get(xRec."No.") then;
        CurrPage.Activate(true);
    end;

    local procedure ReloadServiceConnections()
    begin
        DeleteAll();
        OnRegisterServiceConnection(Rec);
    end;
}

