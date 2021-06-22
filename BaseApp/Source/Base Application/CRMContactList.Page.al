page 5342 "CRM Contact List"
{
    ApplicationArea = Suite;
    Caption = 'Contacts - Common Data Service';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Contact";
    SourceTableView = SORTING(FullName);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(FullName; FullName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    StyleExpr = FirstColumnStyle;
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
                field(EMailAddress1; EMailAddress1)
                {
                    ApplicationArea = Suite;
                    Caption = 'Email Address';
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address.';
                }
                field(Fax; Fax)
                {
                    ApplicationArea = Suite;
                    Caption = 'Fax';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(WebSiteUrl; WebSiteUrl)
                {
                    ApplicationArea = Suite;
                    Caption = 'Website URL';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(MobilePhone; MobilePhone)
                {
                    ApplicationArea = Suite;
                    Caption = 'Mobile Phone';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Pager; Pager)
                {
                    ApplicationArea = Suite;
                    Caption = 'Pager';
                    ToolTip = 'Specifies data from a corresponding field in a Common Data Service entity. For more information about Common Data Service, see Common Data Service Help Center.';
                }
                field(Telephone1; Telephone1)
                {
                    ApplicationArea = Suite;
                    Caption = 'Telephone';
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
                Caption = 'Create Contact in Business Central';
                Image = NewCustomer;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Create a contact in Dynamics 365 that is linked to the Common Data Service contact.';

                trigger OnAction()
                var
                    CRMContact: Record "CRM Contact";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(CRMContact);
                    CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMContact);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(ContactId, DATABASE::Contact, RecordID) then
            if CurrentlyCoupledCRMContact.ContactId = ContactId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
            end
        else begin
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
        SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Contact"));
        FilterGroup(0);
    end;

    var
        CurrentlyCoupledCRMContact: Record "CRM Contact";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCRMContact(CRMContact: Record "CRM Contact")
    begin
        CurrentlyCoupledCRMContact := CRMContact;
    end;
}

