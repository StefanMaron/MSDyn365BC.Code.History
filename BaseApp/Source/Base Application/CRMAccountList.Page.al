page 5341 "CRM Account List"
{
    ApplicationArea = Suite;
    Caption = 'Accounts - Common Data Service';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Account";
    SourceTableView = SORTING(Name);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Address1_PrimaryContactName; Address1_PrimaryContactName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Primary Contact Name';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(CustomerTypeCode; CustomerTypeCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Relationship Type';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Address1_Line1; Address1_Line1)
                {
                    ApplicationArea = Suite;
                    Caption = 'Street 1';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Address1_Line2; Address1_Line2)
                {
                    ApplicationArea = Suite;
                    Caption = 'Street 2';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Address1_PostalCode; Address1_PostalCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'ZIP/Postal Code';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Address1_City; Address1_City)
                {
                    ApplicationArea = Suite;
                    Caption = 'City';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Address1_Country; Address1_Country)
                {
                    ApplicationArea = Suite;
                    Caption = 'Country/Region';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    ToolTip = 'Specifies if the Common Data Service record is coupled to Business Central.';
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
                ToolTip = 'Generate the entity from the coupled Common Data Service account.';

                trigger OnAction()
                var
                    CRMAccount: Record "CRM Account";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(CRMAccount);
                    CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMAccount);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
        EmptyRecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Customer, RecordID) then
            if CurrentlyCoupledCRMAccount.AccountId = AccountId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
            end;

        if RecordID = EmptyRecordID then
            if CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Vendor, RecordID) then
                if CurrentlyCoupledCRMAccount.AccountId = AccountId then begin
                    Coupled := 'Current';
                    FirstColumnStyle := 'Strong';
                end else begin
                    Coupled := 'Yes';
                    FirstColumnStyle := 'Subordinate';
                end;

        if RecordID = EmptyRecordID then begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
        end;
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");

        FilterGroup(4);
        SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Account"));
        FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMAccount: Record "CRM Account";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMAccount(CRMAccount: Record "CRM Account")
    begin
        CurrentlyCoupledCRMAccount := CRMAccount;
    end;
}