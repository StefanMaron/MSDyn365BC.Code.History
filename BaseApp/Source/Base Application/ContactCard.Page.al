page 5050 "Contact Card"
{
    Caption = 'Contact Card';
    PageType = ListPlus;
    PromotedActionCategories = 'New,Process,Report,Navigate';
    SourceTable = Contact;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    AssistEdit = true;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the contact. If the contact is a person, you can click the field to see the Name Details window.';

                    trigger OnAssistEdit()
                    var
                        Contact: Record Contact;
                    begin
                        CurrPage.SaveRecord();
                        Commit();

                        Contact := Rec;
                        Contact.SetRecFilter();
                        if Contact.Type = Contact.Type::Person then begin
                            Clear(NameDetails);
                            NameDetails.SetTableView(Contact);
                            NameDetails.SetRecord(Contact);
                            NameDetails.RunModal;
                        end else begin
                            Clear(CompanyDetails);
                            CompanyDetails.SetTableView(Contact);
                            CompanyDetails.SetRecord(Contact);
                            CompanyDetails.RunModal;
                        end;
                        Rec := Contact;
                        CurrPage.Update(false);
                    end;
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of contact, either company or person.';

                    trigger OnValidate()
                    begin
                        TypeOnAfterValidate;
                    end;
                }
                field("Company No."; "Company No.")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the number for the contact''s company.';
                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = All;
                    AssistEdit = true;
                    Enabled = CompanyNameEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the company. If the contact is a person, Specifies the name of the company for which this contact works. This field is not editable.';

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        LookupCompany();
                        CurrPage.Update(false);
                    end;
                }
                field(IntegrationCustomerNo; IntegrationCustomerNo)
                {
                    ApplicationArea = All;
                    Caption = 'Integration Customer No.';
                    ToolTip = 'Specifies the number of a customer that is integrated through Dynamics 365 Sales.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        Customer: Record Customer;
                        ContactBusinessRelation: Record "Contact Business Relation";
                    begin
                        if not (IntegrationCustomerNo = '') then begin
                            Customer.Get(IntegrationCustomerNo);
                            ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
                            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                            ContactBusinessRelation.SetRange("No.", Customer."No.");
                            if ContactBusinessRelation.FindFirst then
                                Validate("Company No.", ContactBusinessRelation."Contact No.");
                        end else
                            Validate("Company No.", '');
                    end;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the code of the salesperson who normally handles this contact.';
                }
                field("Salutation Code"; "Salutation Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the salutation code that will be used when you interact with the contact. The salutation code is only used in Word documents. To see a list of the salutation codes already defined, click the field.';
                }
                field("Organizational Level Code"; "Organizational Level Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = OrganizationalLevelCodeEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies the organizational code for the contact, for example, top management. This field is valid for persons only.';
                }
                field(LastDateTimeModified; GetLastDateTimeModified)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last DateTime Modified';
                    Importance = Additional;
                    ToolTip = 'Specifies the date and time when the contact card was last modified. This field is not editable.';
                }
                field("Date of Last Interaction"; "Date of Last Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the date of the last interaction involving the contact, for example, a received or sent mail, e-mail, or phone call. This field is not editable.';

                    trigger OnDrillDown()
                    var
                        InteractionLogEntry: Record "Interaction Log Entry";
                    begin
                        InteractionLogEntry.SetCurrentKey("Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed");
                        InteractionLogEntry.SetRange("Contact Company No.", "Company No.");
                        InteractionLogEntry.SetFilter("Contact No.", "Lookup Contact No.");
                        InteractionLogEntry.SetRange("Attempt Failed", false);
                        if InteractionLogEntry.FindLast then
                            PAGE.Run(0, InteractionLogEntry);
                    end;
                }
                field("Last Date Attempted"; "Last Date Attempted")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the contact was last contacted, for example, when you tried to call the contact, with or without success. This field is not editable.';

                    trigger OnDrillDown()
                    var
                        InteractionLogEntry: Record "Interaction Log Entry";
                    begin
                        InteractionLogEntry.SetCurrentKey("Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed");
                        InteractionLogEntry.SetRange("Contact Company No.", "Company No.");
                        InteractionLogEntry.SetFilter("Contact No.", "Lookup Contact No.");
                        InteractionLogEntry.SetRange("Initiated By", InteractionLogEntry."Initiated By"::Us);
                        if InteractionLogEntry.FindLast then
                            PAGE.Run(0, InteractionLogEntry);
                    end;
                }
                field("Next Task Date"; "Next Task Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the date of the next task involving the contact.';
                }
                field("Exclude from Segment"; "Exclude from Segment")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies if the contact should be excluded from segments:';
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                }
                field(Minor; Minor)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the person''s age is below the definition of adulthood as recognized by law. Data for minors is blocked until a parent or guardian of the minor provides parental consent. You unblock the data by choosing the Parental Consent Received check box.';

                    trigger OnValidate()
                    begin
                        SetParentalConsentReceivedEnable;
                    end;
                }
                field("Parental Consent Received"; "Parental Consent Received")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ParentalConsentReceivedEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies that a parent or guardian of the minor has provided their consent to allow the minor to use this service. When this check box is selected, data for the minor can be processed.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                group(Control37)
                {
                    Caption = 'Address';
                    field(Address; Address)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the contact''s address.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the city where the contact is located.';
                    }
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the contact''s address on your preferred map website.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update(true);
                            DisplayMap;
                        end;
                    }
                }
                group(ContactDetails)
                {
                    Caption = 'Contact';
                    field("Phone No."; "Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the contact''s phone number.';
                    }
                    field("Mobile Phone No."; "Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the contact''s mobile telephone number.';
                    }
                    field("E-Mail"; "E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        ExtendedDatatype = EMail;
                        Importance = Promoted;
                        ToolTip = 'Specifies the email address of the contact.';
                    }
                    field("Fax No."; "Fax No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the contact''s fax number.';
                    }
                    field("Home Page"; "Home Page")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the contact''s web site.';
                    }
                    field("Correspondence Type"; "Correspondence Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the preferred type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';
                    }
                    field("Language Code"; "Language Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    }
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    Enabled = CurrencyCodeEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the contact.';
                }
                field("Territory Code"; "Territory Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Additional;
                    ToolTip = 'Specifies the territory code for the contact.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    Enabled = VATRegistrationNoEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies the contact''s VAT registration number. This field is valid for companies only.';

                    trigger OnDrillDown()
                    var
                        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                    begin
                        VATRegistrationLogMgt.AssistEditContactVATReg(Rec);
                    end;
                }
            }
            part("Profile Questionnaire"; "Contact Card Subform")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Profile Questionnaire';
                SubPageLink = "Contact No." = FIELD("No.");
            }
        }
        area(factboxes)
        {
            part(Control41; "Contact Picture")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = NOT IsOfficeAddin;
            }
            part(Control31; "Contact Statistics FactBox")
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
                        ToolTip = 'View or edit the contact''s business relations, such as customers, vendors, banks, lawyers, consultants, competitors, and so on.';

                        trigger OnAction()
                        var
                            ContactBusinessRelationRec: Record "Contact Business Relation";
                        begin
                            CheckContactType(Type::Company);
                            ContactBusinessRelationRec.SetRange("Contact No.", "Company No.");
                            PAGE.Run(PAGE::"Contact Business Relations", ContactBusinessRelationRec);
                        end;
                    }
                    action("Industry Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Industry Groups';
                        Image = IndustryGroups;
                        ToolTip = 'View or edit the industry groups, such as Retail or Automobile, that the contact belongs to.';

                        trigger OnAction()
                        var
                            ContactIndustryGroupRec: Record "Contact Industry Group";
                        begin
                            CheckContactType(Type::Company);
                            ContactIndustryGroupRec.SetRange("Contact No.", "Company No.");
                            PAGE.Run(PAGE::"Contact Industry Groups", ContactIndustryGroupRec);
                        end;
                    }
                    action("Web Sources")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Web Sources';
                        Image = Web;
                        ToolTip = 'View a list of the web sites with information about the contact.';

                        trigger OnAction()
                        var
                            ContactWebSourceRec: Record "Contact Web Source";
                        begin
                            CheckContactType(Type::Company);
                            ContactWebSourceRec.SetRange("Contact No.", "Company No.");
                            PAGE.Run(PAGE::"Contact Web Sources", ContactWebSourceRec);
                        end;
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
                    Visible = ActionVisible;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
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
            }
            group(ActionGroupCRM)
            {
                Caption = 'Common Data Service';
                Enabled = (Type <> Type::Company) AND ("Company No." <> '');
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                action(CRMGotoContact)
                {
                    ApplicationArea = Suite;
                    Caption = 'Contact';
                    Image = CoupledContactPerson;
                    ToolTip = 'Open the coupled Common Data Service contact.';

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
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Common Data Service.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Common Data Service record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Common Data Service contact.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Common Data Service contact.';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(RecordId);
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
                action("C&ustomer/Vendor/Bank Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer/Vendor/Bank Acc./Employee';
                    Image = ContactReference;
                    ToolTip = 'View the related customer, vendor, bank account, or employee that is associated with the current record.';

                    trigger OnAction()
                    begin
                        ShowCustVendBank;
                    end;
                }
                action("Online Map")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        DisplayMap;
                    end;
                }
                action("Office Customer/Vendor")
                {
                    ApplicationArea = All;
                    Caption = 'Customer/Vendor';
                    Image = ContactReference;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'View the related customer, vendor, or bank account.';
                    Visible = IsOfficeAddin;

                    trigger OnAction()
                    begin
                        ShowCustVendBank;
                    end;
                }
            }
            group(Prices)
            {
                action(PriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Lists (Prices)';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different prices for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, PriceType::Sale, AmountType::Price);
                    end;
                }
                action(PriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, PriceType::Sale, AmountType::Discount);
                    end;
                }
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
                    RunPageView = SORTING("Contact Company No.", Date, "Contact No.", Closed);
                    ToolTip = 'View all marketing tasks that involve the contact person.';
                }
                action("Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Oppo&rtunities';
                    Image = OpportunityList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Contact Company No." = FIELD("Company No."),
                                  "Contact No." = FILTER(<> ''),
                                  "Contact No." = FIELD(FILTER("Lookup Contact No."));
                    RunPageView = SORTING("Contact Company No.", "Contact No.");
                    ToolTip = 'View the sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
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
                    RunPageView = SORTING("Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed");
                    ToolTip = 'View postponed interactions for the contact.';
                    Visible = ActionVisible;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action(SalesQuotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales &Quotes';
                    Image = Quote;
                    Promoted = true;
                    PromotedCategory = Process;
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
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "Contact Company No." = FIELD("Company No."),
                                  "Contact No." = FILTER(<> ''),
                                  "Contact No." = FIELD(FILTER("Lookup Contact No."));
                    RunPageView = SORTING("Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a list of the interactions that you have logged, for example, when you create an interaction, print a cover sheet, a sales order, and so on.';
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Contact Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Launch &Web Source")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Launch &Web Source';
                    Image = LaunchWeb;
                    ToolTip = 'Search for information about the contact online.';
                    Visible = ActionVisible;

                    trigger OnAction()
                    var
                        ContactWebSource: Record "Contact Web Source";
                    begin
                        ContactWebSource.SetRange("Contact No.", "Company No.");
                        if PAGE.RunModal(PAGE::"Web Source Launch", ContactWebSource) = ACTION::LookupOK then
                            ContactWebSource.Launch;
                    end;
                }
                action("Print Cover &Sheet")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Print Cover &Sheet';
                    Image = PrintCover;
                    ToolTip = 'View cover sheets to send to your contact.';

                    trigger OnAction()
                    var
                        Cont: Record Contact;
                    begin
                        Cont := Rec;
                        Cont.SetRecFilter();
                        REPORT.Run(REPORT::"Contact - Cover Sheet", true, false, Cont);
                    end;
                }
                group("Create as")
                {
                    Caption = 'Create as';
                    Image = CustomerContact;
                    action(CreateCustomer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer';
                        Image = Customer;
                        ToolTip = 'Create the contact as a customer.';

                        trigger OnAction()
                        begin
                            CreateCustomer(ChooseCustomerTemplate);
                        end;
                    }
                    action(CreateVendor)
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
                    action(CreateBank)
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
                            CreateEmployee();
                        end;
                    }
                }
                group("Link with existing")
                {
                    Caption = 'Link with existing';
                    Image = Links;
                    Visible = ActionVisible;
                    action(Customer)
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
                    action(Vendor)
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
                    action(Bank)
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
                }
                action("Apply Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Ellipsis = true;
                    Image = ApplyTemplate;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Select a defined template to quickly create a new record.';

                    trigger OnAction()
                    var
                        ConfigTemplateMgt: Codeunit "Config. Template Management";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        ConfigTemplateMgt.UpdateFromTemplateSelection(RecRef);
                    end;
                }
                action(MergeDuplicate)
                {
                    AccessByPermission = TableData "Merge Duplicates Buffer" = RIMD;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Merge With';
                    Ellipsis = true;
                    Image = ItemSubstitution;
                    ToolTip = 'Merge two contact records into one. Before merging, review which field values you want to keep or override. The merge action cannot be undone.';

                    trigger OnAction()
                    var
                        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
                    begin
                        TempMergeDuplicatesBuffer.Show(DATABASE::Contact, "No.");
                    end;
                }
                action(CreateAsCustomer)
                {
                    ApplicationArea = All;
                    Caption = 'Create as Customer';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create a new customer based on this contact.';
                    Visible = IsOfficeAddin;

                    trigger OnAction()
                    begin
                        CreateCustomer(ChooseCustomerTemplate);
                    end;
                }
                action(CreateAsVendor)
                {
                    ApplicationArea = All;
                    Caption = 'Create as Vendor';
                    Image = Vendor;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create a new vendor based on this contact.';
                    Visible = IsOfficeAddin;

                    trigger OnAction()
                    begin
                        CreateVendor;
                    end;
                }
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
                    CreateSalesQuoteFromContact();
                end;
            }
        }
        area(reporting)
        {
            action(ContactCoverSheet)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Contact Cover Sheet';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'Print or save cover sheets to send to one or more of your contacts.';

                trigger OnAction()
                var
                    Contact: Record Contact;
                    ContactCoverSheetReportID: Integer;
                begin
                    Contact := Rec;
                    Contact.SetRecFilter();
                    ContactCoverSheetReportID := REPORT::"Contact Cover Sheet";
                    OnBeforePrintContactCoverSheet(ContactCoverSheetReportID);
                    REPORT.Run(ContactCoverSheetReportID, true, false, Contact);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CRMIntegrationEnabled or CDSIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
            if "No." <> xRec."No." then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;

        xRec := Rec;
        EnableFields();

        if Type = Type::Person then
            IntegrationFindCustomerNo()
        else
            IntegrationCustomerNo := '';
    end;

    trigger OnInit()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        OrganizationalLevelCodeEnable := true;
        CompanyNameEnable := true;
        VATRegistrationNoEnable := true;
        CurrencyCodeEnable := true;
        ActionVisible := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Windows;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Contact: Record Contact;
    begin
        if GetFilter("Company No.") <> '' then begin
            "Company No." := GetRangeMax("Company No.");
            Type := Type::Person;
            Contact.Get("Company No.");
            InheritCompanyToPersonData(Contact);
        end;
    end;

    trigger OnOpenPage()
    var
        OfficeManagement: Codeunit "Office Management";
    begin
        IsOfficeAddin := OfficeManagement.IsAvailable;
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled;
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        SetNoFieldVisible;
        SetParentalConsentReceivedEnable;
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        CompanyDetails: Page "Company Details";
        NameDetails: Page "Name Details";
        IntegrationCustomerNo: Code[20];
        [InDataSet]
        CurrencyCodeEnable: Boolean;
        [InDataSet]
        VATRegistrationNoEnable: Boolean;
        [InDataSet]
        CompanyNameEnable: Boolean;
        [InDataSet]
        OrganizationalLevelCodeEnable: Boolean;
        CompanyGroupEnabled: Boolean;
        PersonGroupEnabled: Boolean;
        ExtendedPriceEnabled: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        IsOfficeAddin: Boolean;
        ActionVisible: Boolean;
        ShowMapLbl: Label 'Show Map';
        NoFieldVisible: Boolean;
        ParentalConsentReceivedEnable: Boolean;

    local procedure EnableFields()
    begin
        CompanyGroupEnabled := Type = Type::Company;
        PersonGroupEnabled := Type = Type::Person;
        CurrencyCodeEnable := Type = Type::Company;
        VATRegistrationNoEnable := Type = Type::Company;
        CompanyNameEnable := Type = Type::Person;
        OrganizationalLevelCodeEnable := Type = Type::Person;
    end;

    local procedure IntegrationFindCustomerNo()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "Contact No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", "Company No.");
        if ContactBusinessRelation.FindFirst then begin
            IntegrationCustomerNo := ContactBusinessRelation."No.";
        end else
            IntegrationCustomerNo := '';
    end;

    local procedure TypeOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.ContactNoIsVisible;
    end;

    local procedure SetParentalConsentReceivedEnable()
    begin
        if Minor then
            ParentalConsentReceivedEnable := true
        else begin
            "Parental Consent Received" := false;
            ParentalConsentReceivedEnable := false;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintContactCoverSheet(var ContactCoverSheetReportID: Integer)
    begin
    end;
}

