page 5052 "Contact List"
{
    ApplicationArea = Basic, Suite, Service;
    Caption = 'Contacts';
    CardPageID = "Contact Card";
    DataCaptionFields = "Company No.";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Contact,Navigate';
    SourceTable = Contact;
    SourceTableView = SORTING("Company Name", "Company No.", Type, Name);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the name of the contact. If the contact is a person, you can click the field to see the Name Details window.';
                }
                field("Name 2"; "Name 2")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name.';
                    Visible = false;
                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the company. If the contact is a person, Specifies the name of the company for which this contact works. This field is not editable.';
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the contact''s job title.';
                    Visible = false;
                }
                field("Business Relation"; Rec."Contact Business Relation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the existing business relation.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s phone number.';
                }
                field("Mobile Phone No."; "Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s mobile telephone number.';
                    Visible = false;
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the contact''s email.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s fax number.';
                    Visible = false;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the salesperson who normally handles this contact.';
                }
                field("Territory Code"; "Territory Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the territory code for the contact.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the contact.';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    Visible = false;
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county of the contact.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                    Visible = false;
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
                field(Minor; Minor)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the person''s age is below the definition of adulthood as recognized by law. Data for minors is blocked until a parent or guardian of the minor provides parental consent. You unblock the data by selecting the Parental Consent Received check box.';
                    Visible = false;
                }
                field("Parental Consent Received"; "Parental Consent Received")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that a parent or guardian of the minor has provided their consent to allow the minor to use this service. When this check box is selected, data for the minor can be processed.';
                    Visible = false;
                }
                field("Coupled to CRM"; "Coupled to CRM")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the contact is coupled to a contact in Dataverse.';
                    Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                }
            }
        }
        area(factboxes)
        {
            part(Control128; "Contact Statistics FactBox")
            {
                ApplicationArea = RelationshipMgmt;
                SubPageLink = "No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("C&ontact")
            {
                Caption = 'C&ontact';
                Image = ContactPerson;
                group("Comp&any")
                {
                    Caption = 'Comp&any';
                    Enabled = CompanyGroupEnabled;
                    Image = Company;
                    action("Business Relations")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Business Relations';
                        Image = BusinessRelation;
                        RunObject = Page "Contact Business Relations";
                        RunPageLink = "Contact No." = FIELD("Company No.");
                        ToolTip = 'View or edit the contact''s business relations, such as customers, vendors, banks, lawyers, consultants, competitors, and so on.';
                    }
                    action("Industry Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Industry Groups';
                        Image = IndustryGroups;
                        RunObject = Page "Contact Industry Groups";
                        RunPageLink = "Contact No." = FIELD("Company No.");
                        ToolTip = 'View or edit the industry groups, such as Retail or Automobile, that the contact belongs to.';
                    }
                    action("Web Sources")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Web Sources';
                        Image = Web;
                        RunObject = Page "Contact Web Sources";
                        RunPageLink = "Contact No." = FIELD("Company No.");
                        ToolTip = 'View a list of the web sites with information about the contacts.';
                    }
                }
                group("P&erson")
                {
                    Caption = 'P&erson';
                    Enabled = PersonGroupEnabled;
                    Image = User;
                    action("Job Responsibilities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Job Responsibilities';
                        Image = Job;
                        ToolTip = 'View or edit the contact''s job responsibilities.';

                        trigger OnAction()
                        var
                            ContJobResp: Record "Contact Job Responsibility";
                        begin
                            CheckContactType(Type::Person);
                            ContJobResp.SetRange("Contact No.", "No.");
                            PAGE.RunModal(PAGE::"Contact Job Responsibilities", ContJobResp);
                        end;
                    }
                }
                action("Pro&files")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Pro&files';
                    Image = Answers;
                    ToolTip = 'Open the Profile Questionnaires window.';

                    trigger OnAction()
                    var
                        ProfileManagement: Codeunit ProfileManagement;
                    begin
                        ProfileManagement.ShowContactQuestionnaireCard(Rec, '', 0);
                    end;
                }
                action("&Picture")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = '&Picture';
                    Image = Picture;
                    RunObject = Page "Contact Picture";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'View or add a picture of the contact person or, for example, the company''s logo.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Contact),
                                  "No." = FIELD("No."),
                                  "Sub No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
                group("Alternati&ve Address")
                {
                    Caption = 'Alternati&ve Address';
                    Image = Addresses;
                    action(Card)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Card';
                        Image = EditLines;
                        RunObject = Page "Contact Alt. Address List";
                        RunPageLink = "Contact No." = FIELD("No.");
                        ToolTip = 'View or change detailed information about the contact.';
                    }
                    action("Date Ranges")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date Ranges';
                        Image = DateRange;
                        RunObject = Page "Contact Alt. Addr. Date Ranges";
                        RunPageLink = "Contact No." = FIELD("No.");
                        ToolTip = 'Specify date ranges that apply to the contact''s alternate address.';
                    }
                }
#if not CLEAN19
                action(SentEmails)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action SentEmails moved under history';
                    ObsoleteTag = '19.0';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to this contact.';
                    Visible = false;

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::Contact, Rec.SystemId);
                    end;
                }
#endif
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dataverse';
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                action(CRMGotoContact)
                {
                    ApplicationArea = Suite;
                    Caption = 'Contact';
                    Enabled = (Type <> Type::Company) AND ("Company No." <> '');
                    Image = CoupledContactPerson;
                    ToolTip = 'Open the coupled Dataverse contact.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Enabled = (Type <> Type::Company) AND ("Company No." <> '');
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Dataverse.';

                    trigger OnAction()
                    var
                        Contact: Record Contact;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        ContactRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Contact);
                        Contact.Next;

                        if Contact.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Contact.RecordId)
                        else begin
                            ContactRecordRef.GetTable(Contact);
                            CRMIntegrationManagement.UpdateMultipleNow(ContactRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Enabled = (Type <> Type::Company) AND ("Company No." <> '');
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse contact.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(RecordId);
                        end;
                    }
                    action(MatchBasedCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledContactPerson;
                        ToolTip = 'Couple contacts to contacts in Dataverse based on criteria.';

                        trigger OnAction()
                        var
                            Contact: Record Contact;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Contact);
                            RecRef.GetTable(Contact);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse contact.';

                        trigger OnAction()
                        var
                            Contact: Record Contact;
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Contact);
                            RecRef.GetTable(Contact);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                group(Create)
                {
                    Caption = 'Create';
                    Image = NewCustomer;
                    action(CreateInCRM)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Contact in Dataverse';
                        Enabled = (Type <> Type::Company) AND ("Company No." <> '');
                        Image = NewCustomer;
                        ToolTip = 'Create a contact in Dataverse that is linked to a contact in your company.';

                        trigger OnAction()
                        var
                            Contact: Record Contact;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CurrPage.SetSelectionFilter(Contact);
                            CRMIntegrationManagement.CreateNewRecordsInCRM(Contact);
                        end;
                    }
                    action(CreateFromCRM)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Contact in Business Central';
                        Image = NewCustomer;
                        ToolTip = 'Create a contact here in your company that is linked to the Dataverse contact.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.CreateNewContactFromCRM;
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the contact table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(RecordId);
                    end;
                }
            }
            group("Related Information")
            {
                Caption = 'Related Information';
                Image = Users;
                action("Relate&d Contacts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Relate&d Contacts';
                    Image = Users;
                    RunObject = Page "Contact List";
                    RunPageLink = "Company No." = FIELD("Company No.");
                    ToolTip = 'View a list of all contacts.';
                }
                action("Segmen&ts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segmen&ts';
                    Image = Segment;
                    RunObject = Page "Contact Segment List";
                    RunPageLink = "Contact Company No." = FIELD("Company No."),
                                  "Contact No." = FILTER(<> ''),
                                  "Contact No." = FIELD(FILTER("Lookup Contact No."));
                    RunPageView = SORTING("Contact No.", "Segment No.");
                    ToolTip = 'View the segments that are related to the contact.';
                }
                action("Mailing &Groups")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Mailing &Groups';
                    Image = DistributionGroup;
                    RunObject = Page "Contact Mailing Groups";
                    RunPageLink = "Contact No." = FIELD("No.");
                    ToolTip = 'View or edit the mailing groups that the contact is assigned to, for example, for sending price lists or Christmas cards.';
                }
#if not CLEAN18
                action("C&ustomer/Vendor/Bank Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer/Vendor/Bank Acc./Employee';
                    Image = ContactReference;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by 4 actions: RelatedCustomer, RelatedVendor, RelatedBank, RelatedEmployee';
                    ObsoleteTag = '18.0';
                    Visible = false;
                    ToolTip = 'View the related customer, vendor, bank account, or employee that is associated with the current record.';

                    trigger OnAction()
                    begin
                        ShowCustVendBank;
                    end;
                }
#endif
                action(RelatedCustomer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Enabled = RelatedCustomerEnabled;
                    ToolTip = 'View the related customer that is associated with the current record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::Customer, false);
                    end;
                }
                action(RelatedVendor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor';
                    Image = Vendor;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Enabled = RelatedVendorEnabled;
                    ToolTip = 'View the related vendor that is associated with the current record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::Vendor, false);
                    end;
                }
                action(RelatedBank)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account';
                    Image = BankAccount;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Enabled = RelatedBankEnabled;
                    ToolTip = 'View the related bank account that is associated with the current record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::"Bank Account", false);
                    end;
                }
                action(RelatedEmployee)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee';
                    Image = Employee;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Enabled = RelatedEmployeeEnabled;
                    ToolTip = 'View the related employee that is associated with the current record.';

                    trigger OnAction()
                    var
                        LinkToTable: Enum "Contact Business Relation Link To Table";
                    begin
                        Rec.ShowBusinessRelation(LinkToTable::Employee, false);
                    end;
                }
            }
            group(Prices)
            {
                action(PriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Price Lists';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lists for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, "Price Type"::Sale, "Price Amount Type"::Any);
                    end;
                }
                action(PriceLines)
                {
                    AccessByPermission = TableData "Sales Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lines for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, "Price Amount Type"::Price);
                    end;
                }
                action(DiscountLines)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = LineDiscount;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, "Price Amount Type"::Discount);
                    end;
                }
#if not CLEAN18
                action(PriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = false;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action PriceLists shows all sales price lists with prices and discounts';
                    ObsoleteTag = '18.0';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, PriceType::Sale, AmountType::Discount);
                    end;
                }
#endif
            }
            group(Tasks)
            {
                Caption = 'Tasks';
                Image = Task;
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Contact Company No." = FIELD("Company No."),
                                  "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                  "System To-do Type" = FILTER("Contact Attendee");
                    RunPageView = SORTING("Contact Company No.", "Contact No.");
                    ToolTip = 'View all marketing tasks that involve the contact person.';
                }
                action("Open Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Open Oppo&rtunities';
                    Image = OpportunityList;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Contact Company No." = FIELD("Company No."),
                                  "Contact No." = FILTER(<> ''),
                                  "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                  Status = FILTER("Not Started" | "In Progress");
                    RunPageView = SORTING("Contact Company No.", "Contact No.");
                    Scope = Repeater;
                    ToolTip = 'View the open sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "Contact Company No." = FIELD("Company No."),
                                  "Contact No." = FILTER(<> ''),
                                  "Contact No." = FIELD(FILTER("Lookup Contact No."));
                    RunPageView = SORTING("Contact Company No.", "Contact No.");
                    ToolTip = 'View postponed interactions for the contact.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action(ShowSalesQuotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales &Quotes';
                    Image = Quote;
                    RunObject = Page "Sales Quotes";
                    RunPageLink = "Sell-to Contact No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Sell-to Contact No.");
                    ToolTip = 'View sales quotes that exist for the contact.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Closed Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Closed Oppo&rtunities';
                    Image = OpportunityList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Contact Company No." = FIELD("Company No."),
                                  "Contact No." = FILTER(<> ''),
                                  "Contact No." = FIELD(FILTER("Lookup Contact No.")),
                                  Status = FILTER(Won | Lost);
                    RunPageView = SORTING("Contact Company No.", "Contact No.");
                    ToolTip = 'View the closed sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Contact Company No." = FIELD("Company No."),
                                  "Contact No." = FILTER(<> ''),
                                  "Contact No." = FIELD(FILTER("Lookup Contact No."));
                    RunPageView = SORTING("Contact Company No.", "Contact No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Contact Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Sent Emails")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to this contact.';
                    Visible = EmailImprovementFeatureEnabled;

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::Contact, Rec.SystemId);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(MakePhoneCall)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Make &Phone Call';
                    Image = Calls;
                    Promoted = true;
                    PromotedCategory = Process;
                    Scope = Repeater;
                    ToolTip = 'Call the selected contact.';

                    trigger OnAction()
                    var
                        TAPIManagement: Codeunit TAPIManagement;
                    begin
                        TAPIManagement.DialContCustVendBank(DATABASE::Contact, "No.", GetDefaultPhoneNo, '');
                    end;
                }
                action("Launch &Web Source")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Launch &Web Source';
                    Image = LaunchWeb;
                    ToolTip = 'Search for information about the contact online.';

                    trigger OnAction()
                    var
                        ContactWebSource: Record "Contact Web Source";
                    begin
                        ContactWebSource.SetRange("Contact No.", "Company No.");
                        if PAGE.RunModal(PAGE::"Web Source Launch", ContactWebSource) = ACTION::LookupOK then
                            ContactWebSource.Launch;
                    end;
                }
                group("Create as")
                {
                    Caption = 'Create as';
                    Image = CustomerContact;
                    action(Customer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer';
                        Image = Customer;
                        ToolTip = 'Create the contact as a customer.';

                        trigger OnAction()
                        begin
                            CreateCustomer();
                        end;
                    }
                    action(Vendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor';
                        Image = Vendor;
                        ToolTip = 'Create the contact as a vendor.';

                        trigger OnAction()
                        begin
                            CreateVendor;
                        end;
                    }
                    action(Bank)
                    {
                        AccessByPermission = TableData "Bank Account" = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank';
                        Image = Bank;
                        ToolTip = 'Create the contact as a bank.';

                        trigger OnAction()
                        begin
                            CreateBankAccount;
                        end;
                    }
                    action(CreateEmployee)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee';
                        Image = Employee;
                        ToolTip = 'Create the contact as an employee.';

                        trigger OnAction()
                        begin
                            Rec.CreateEmployee();
                        end;
                    }
                }
                group("Link with existing")
                {
                    Caption = 'Link with existing';
                    Image = Links;
                    action(Action63)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer';
                        Image = Customer;
                        ToolTip = 'Link the contact to an existing customer.';

                        trigger OnAction()
                        begin
                            CreateCustomerLink;
                        end;
                    }
                    action(Action64)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor';
                        Image = Vendor;
                        ToolTip = 'Link the contact to an existing vendor.';

                        trigger OnAction()
                        begin
                            CreateVendorLink;
                        end;
                    }
                    action(Action65)
                    {
                        AccessByPermission = TableData "Bank Account" = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank';
                        Image = Bank;
                        ToolTip = 'Link the contact to an existing bank.';

                        trigger OnAction()
                        begin
                            CreateBankAccountLink;
                        end;
                    }
                    action(LinkEmployee)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee';
                        Image = Employee;
                        ToolTip = 'Link the contact to an existing employee.';

                        trigger OnAction()
                        begin
                            CreateEmployeeLink();
                        end;
                    }
                }
            }
            action("Export Contact")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Contact';
                Image = Export;
                ToolTip = 'Export Contact';
                Enabled = ExportContactEnabled;

                trigger OnAction()
                var
                    Contact: Record Contact;
                    ExportContact: XMLport "Export Contact";
                begin
                    CurrPage.SetSelectionFilter(Contact);
                    ExportContact.SetTableView(Contact);
                    ExportContact.Run();
                end;
            }
            action("Create &Interaction")
            {
                AccessByPermission = TableData Attachment = R;
                ApplicationArea = RelationshipMgmt;
                Caption = 'Create &Interaction';
                Image = CreateInteraction;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Create an interaction with a specified contact.';

                trigger OnAction()
                begin
                    CreateInteraction;
                end;
            }
            action("Create Opportunity")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Create Opportunity';
                Image = NewOpportunity;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Opportunity Card";
                RunPageLink = "Contact No." = FIELD("No."),
                              "Contact Company No." = FIELD("Company No.");
                RunPageMode = Create;
                ToolTip = 'Register a sales opportunity for the contact.';
            }
            action(WordTemplate)
            {
                ApplicationArea = All;
                Caption = 'Apply Word Template';
                ToolTip = 'Apply a Word template on the selected records.';
                Image = Word;

                trigger OnAction()
                var
                    Contact: Record Contact;
                    WordTemplateSelectionWizard: Page "Word Template Selection Wizard";
                begin
                    CurrPage.SetSelectionFilter(Contact);
                    WordTemplateSelectionWizard.SetData(Contact);
                    WordTemplateSelectionWizard.RunModal();
                end;
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this contact.';
                Promoted = true;
                PromotedCategory = Process;
                Enabled = CanSendEmail;

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::Contact, Rec.SystemId);
                    TempEmailItem.AddRelatedSourceDocuments(Database::Contact, Rec.SystemId);
                    TempEmailitem."Send to" := Rec."E-Mail";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
            action(SyncWithExchange)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sync with Office 365';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Synchronize with Office 365 based on last sync date and last modified date. All changes in Office 365 since the last sync date will be synchronized back.';

                trigger OnAction()
                begin
                    SyncExchangeContacts(false);
                end;
            }
            action(FullSyncWithExchange)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Full Sync with Office 365';
                Image = RefreshLines;
                ToolTip = 'Synchronize, but ignore the last synchronized and last modified dates. All changes will be pushed to Office 365 and take all contacts from your Exchange folder and sync back.';

                trigger OnAction()
                begin
                    SyncExchangeContacts(true);
                end;
            }
        }
        area(creation)
        {
            action(NewSalesQuote)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Sales Quote';
                Image = NewSalesQuote;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Offer items or services to a customer.';

                trigger OnAction()
                begin
                    CreateSalesQuoteFromContact;
                end;
            }
        }
        area(reporting)
        {
            action("Contact Labels")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Contact Labels';
                Image = "Report";
                RunObject = Report "Contact - Labels";
                ToolTip = 'View mailing labels with names and addresses of your contacts. For example, you can use the report to review contact information before you send sales and marketing campaign letters.';
            }
            action("Questionnaire Handout")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Questionnaire Handout';
                Image = "Report";
                RunObject = Report "Questionnaire - Handouts";
                ToolTip = 'View your profile questionnaire for the contact. You can print this report to have a printed copy of the questions that are within the profile questionnaire.';
            }
            action("Sales Cycle Analysis")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Sales Cycle Analysis';
                Image = "Report";
                RunObject = Report "Sales Cycle - Analysis";
                ToolTip = 'View information about your sales cycles. The report includes details about the sales cycle, such as the number of opportunities currently at that stage, the estimated and calculated current values of opportunities created using the sales cycle, and so on.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Contact: Record Contact;
    begin
        EnableFields;
        if CRMIntegrationEnabled or CDSIntegrationEnabled then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
        SetEnabledRelatedActions();

        CurrPage.SetSelectionFilter(Contact);
        CanSendEmail := Contact.Count() = 1;
    end;

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := Type = Type::Company;
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        EmailFeature: Codeunit "Email Feature";
    begin
        EmailImprovementFeatureEnabled := EmailFeature.IsEnabled();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled;
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();

        UpdateContactBusinessRelationOnContacts();
    end;

    local procedure UpdateContactBusinessRelationOnContacts()
    var
        ContactToUpdate: Record Contact;
        ContactRec: Record Contact;
        ContactBusinessRelation: Enum "Contact Business Relation";
    begin
        ContactRec.SetRange("Contact Business Relation", ContactBusinessRelation::" ");
        if ContactRec.IsEmpty() then
            exit;

        ContactRec.FindSet();
        repeat
            ContactToUpdate.Get(ContactRec."No.");
            if (ContactToUpdate.UpdateBusinessRelation()) then
                ContactToUpdate.Modify();
        until ContactRec.Next() = 0;
    end;

    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        [InDataSet]
        CanSendEmail: Boolean;
        [InDataSet]
        StyleIsStrong: Boolean;
        CompanyGroupEnabled: Boolean;
        PersonGroupEnabled: Boolean;
        ExtendedPriceEnabled: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        RelatedCustomerEnabled: Boolean;
        RelatedVendorEnabled: Boolean;
        RelatedBankEnabled: Boolean;
        RelatedEmployeeEnabled: Boolean;
        ExportContactEnabled: Boolean;
        EmailImprovementFeatureEnabled: Boolean;

    local procedure EnableFields()
    begin
        CompanyGroupEnabled := Type = Type::Company;
        PersonGroupEnabled := Type = Type::Person;
        ExportContactEnabled := Rec."No." <> '';
    end;

    local procedure SetEnabledRelatedActions()
    begin
        Rec.HasBusinessRelations(RelatedCustomerEnabled, RelatedVendorEnabled, RelatedBankEnabled, RelatedEmployeeEnabled)
    end;

    [Scope('OnPrem')]
    procedure SyncExchangeContacts(FullSync: Boolean)
    var
        ExchangeSync: Record "Exchange Sync";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ExchangeContactSync: Codeunit "Exchange Contact Sync.";
    begin
        if O365SyncManagement.IsO365Setup(true) then
            if ExchangeSync.Get(UserId) then begin
                ExchangeContactSync.GetRequestParameters(ExchangeSync);
                O365SyncManagement.SyncExchangeContacts(ExchangeSync, FullSync);
            end;
    end;

    procedure GetSelectionFilter(): Text
    var
        Contact: Record Contact;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Contact);
        exit(SelectionFilterManagement.GetSelectionFilterForContact(Contact));
    end;

    procedure SetSelection(var Contact: Record Contact)
    begin
        CurrPage.SetSelectionFilter(Contact);
    end;
}

