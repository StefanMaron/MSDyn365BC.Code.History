page 7211 "CRM Freight Terms List"
{
    ApplicationArea = Suite;
    Caption = 'Freight Terms - Dataverse';
    AdditionalSearchTerms = 'Freight Terms CDS, Freight Terms Common Data Service, Shipment Methods CDS, Shipment Methods Common Data Service, Shipment Methods Dataverse';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Freight Terms";
    SourceTableView = sorting("Code");
    SourceTableTemporary = true;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Code"; "Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Code';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Dataverse record is coupled to Business Central.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(CreateFromCRM)
            {
                ApplicationArea = Suite;
                Caption = 'Create in Business Central';
                Image = NewCustomer;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Generate the entity from the coupled Dataverse Freight terms.';
                Visible = OptionMappingEnabled;

                trigger OnAction()
                var
                    CRMFreightTerms: Record "CRM Freight Terms";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CRMFreightTerms.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(CRMFreightTerms);
                    CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMOptions(CRMFreightTerms);
                end;
            }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Freight Terms';
                Image = FilterLines;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Do not show coupled Freight terms.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Freight Terms';
                Image = ClearFilter;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Show coupled Freight terms.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMAccount: Record "CRM Account";
    begin
        if CRMOptionMapping.FindRecordID(Database::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), Rec."Option Id") then
            if CurrentlyMappedCRMFreightTermOptionId = Rec."Option Id" then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Rec.Mark(true);
        end;
    end;

    trigger OnInit()
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
        Commit();
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagmeent: Codeunit "CRM Integration Management";
    begin
        OptionMappingEnabled := CRMIntegrationManagmeent.IsOptionMappingEnabled();
        LoadRecords();
    end;

    var
        CurrentlyMappedCRMFreightTermOptionId: Integer;
        Coupled: Text;
        FirstColumnStyle: Text;
        LinesLoaded: Boolean;
        OptionMappingEnabled: Boolean;

    procedure SetCurrentlyMappedCRMFreightTermOptionId(OptionId: Integer)
    begin
        CurrentlyMappedCRMFreightTermOptionId := OptionId;
    end;

    procedure GetRec(OptionId: Integer): Record "CRM Freight Terms"
    begin
        if Rec.Get(OptionId) then
            exit(Rec);
    end;

    procedure LoadRecords()
    begin
        if LinesLoaded then
            exit;

        LinesLoaded := Rec.Load();
    end;
}