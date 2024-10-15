page 5200 "Employee Card"
{
    Caption = 'Employee Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Employee,Navigate';
    SourceTable = Employee;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        AssistEdit;
                    end;
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee''s first name.';
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee''s last name.';
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Middle Name/Initials';
                    ToolTip = 'Specifies the employee''s middle name.';
                }
                field(Initials; Initials)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s initials.';
                }
            }
            group("Address & Contact")
            {
                Caption = 'Address & Contact';
                group(Control13)
                {
                    ShowCaption = false;
                    field(Address; Address)
                    {
                        ApplicationArea = BasicHR;
                        ToolTip = 'Specifies the employee''s address.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = BasicHR;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = BasicHR;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control31)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = BasicHR;
                            ToolTip = 'Specifies the county of the employee.';
                        }
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = BasicHR;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = BasicHR;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
                        end;
                    }
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee''s telephone number.';
                }
                field("Short Name"; "Short Name")
                {
                    ApplicationArea = Advanced;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Person No."; "Person No.")
                {
                    ApplicationArea = Advanced;
                }
                field("Position No."; "Position No.")
                {
                    ApplicationArea = Advanced;
                }
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a resource number for the employee, if the employee is a resource in Resources Planning.';
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a salesperson or purchaser code for the employee, if the employee is a salesperson or purchaser in the company.';
                }
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Advanced;
                }
                field("Org. Unit Name"; "Org. Unit Name")
                {
                    ApplicationArea = Advanced;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Advanced;
                    Editable = false;
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = Advanced;
                }
                field("Birth Date"; "Birth Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee''s date of birth.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ToolTip = 'Specifies the last day this entry was modified.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = BasicHR;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field(Extension; Extension)
                {
                    ApplicationArea = Advanced;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee''s telephone extension.';
                }
                field("Mobile Phone No."; "Mobile Phone No.")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee''s mobile telephone number.';
                }
                field(Pager; Pager)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s pager number.';
                }
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee''s telephone number.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the fax number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = BasicHR;
                    ExtendedDatatype = EMail;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee''s email address.';
                }
                field("Company E-Mail"; "Company E-Mail")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee''s email address at the company.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                field("Employment Date"; "Employment Date")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the employee began to work for the company.';
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Advanced;
                    Importance = Promoted;
                }
                field(Status; Status)
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employment status of the employee.';
                }
                field("Inactive Date"; "Inactive Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the employee became inactive, due to disability or maternity leave, for example.';
                }
                field("Cause of Inactivity Code"; "Cause of Inactivity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the cause of inactivity by the employee.';
                }
                field("Termination Date"; "Termination Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date when the employee was terminated, due to retirement or dismissal, for example.';
                }
                field("Grounds for Term. Code"; "Grounds for Term. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a termination code for the employee who has been terminated.';
                }
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Advanced;
                    Editable = false;
                    ToolTip = 'Specifies the category.';
                }
                field("Emplymt. Contract Code"; "Emplymt. Contract Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employment contract code for the employee.';
                }
                field("Statistics Group Code"; "Statistics Group Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a statistics group code to assign to the employee for statistical purposes.';
                }
                field(Gender; Gender)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s gender.';
                }
                field("Social Security No."; "Social Security No.")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ToolTip = 'Specifies the social security number of the employee.';
                }
                field("Union Code"; "Union Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s labor union membership code.';
                }
                field("Union Membership No."; "Union Membership No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s labor union membership number.';
                }
            }
            group(Payroll)
            {
                Caption = 'Payroll';
                field("Payroll Calc Group"; "Payroll Calc Group")
                {
                    ApplicationArea = Advanced;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Advanced;
                }
                field("Calendar Code"; "Calendar Code")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the related work calendar. ';
                }
                field("Employee Vendor No."; "Employee Vendor No.")
                {
                    ApplicationArea = Advanced;
                    Editable = false;
                }
                field("Employee Bank Code"; "Employee Bank Code")
                {
                    ApplicationArea = Advanced;
                    Visible = false;
                }
                field("Tax Payer Category"; "Tax Payer Category")
                {
                    ApplicationArea = Advanced;
                }
                field("Int. Fnds Sick Leave Post. Gr."; "Int. Fnds Sick Leave Post. Gr.")
                {
                    ApplicationArea = Advanced;
                }
                field("Future Period Vacat. Post. Gr."; "Future Period Vacat. Post. Gr.")
                {
                    ApplicationArea = Advanced;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Application Method"; "Application Method")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies how to apply payments to entries for this employee.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(5200),
                              "No." = FIELD("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("E&mployee")
            {
                Caption = 'E&mployee';
                Image = Employee;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Employee),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(5200),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("&Picture")
                {
                    ApplicationArea = BasicHR;
                    Caption = '&Picture';
                    Image = Picture;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Employee Picture";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'View or add a picture of the employee or, for example, the company''s logo.';
                }
                action(AlternativeAddresses)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Alternate Addresses';
                    Image = Addresses;
                    RunObject = Page "Alternative Address List";
                    RunPageLink = "Person No." = FIELD("Person No.");
                    ToolTip = 'Open the list of addresses that are registered for the employee.';
                }
                action("&Relatives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Relatives';
                    Image = Relatives;
                    RunObject = Page "Employee Relatives";
                    RunPageLink = "Person No." = FIELD("Person No.");
                    ToolTip = 'Open the list of relatives that are registered for the employee.';
                }
                action("Mi&sc. Article Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mi&sc. Article Information';
                    Image = Filed;
                    RunObject = Page "Misc. Article Information";
                    RunPageLink = "Employee No." = FIELD("No.");
                    ToolTip = 'Open the list of miscellaneous articles that are registered for the employee.';
                }
                action("&Confidential Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Confidential Information';
                    Image = Lock;
                    RunObject = Page "Confidential Information";
                    RunPageLink = "Employee No." = FIELD("No.");
                    ToolTip = 'Open the list of any confidential information that is registered for the employee.';
                }
                separator(Action1210188)
                {
                }
                action("A&bsence Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'A&bsence Orders';
                    Image = Absence;
                    RunObject = Page "Absence Order List";
                    RunPageLink = "Employee No." = FIELD("No.");
                    ToolTip = 'View absence information for the employee.';
                }
                action(Timesheets)
                {
                    Caption = 'Timesheets';
                    Image = Timesheet;
                    RunObject = Page "Timesheet Status";
                    RunPageLink = "Employee No." = FIELD("No.");
                }
                separator(Action23)
                {
                }
                action("Personal Documents")
                {
                    Caption = 'Personal Documents';
                    Image = Documents;
                    RunObject = Page "Person Documents";
                    RunPageLink = "Person No." = FIELD("Person No.");
                }
                action("Q&ualifications")
                {
                    Caption = 'Q&ualifications';
                    Image = Certificate;
                    RunObject = Page "Employee Qualifications";
                    RunPageLink = "Person No." = FIELD("Person No.");
                }
                action(Attestations)
                {
                    Caption = 'Attestations';
                    Image = Certificate;
                    RunObject = Page "Employee Attestation";
                    RunPageLink = "Person No." = FIELD("Person No.");
                }
                action(Languages)
                {
                    Caption = 'Languages';
                    Image = Language;
                    RunObject = Page "Employee Language";
                    RunPageLink = "Person No." = FIELD("Person No.");
                }
                action("Medical Information")
                {
                    Caption = 'Medical Information';
                    Image = AddWatch;
                    RunObject = Page "Person Medical Information";
                    RunPageLink = "Person No." = FIELD("Person No.");
                }
                separator(Action1210190)
                {
                }
                action("Misc. Articles &Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Misc. Articles &Overview';
                    Image = FiledOverview;
                    RunObject = Page "Misc. Articles Overview";
                    ToolTip = 'View miscellaneous articles that are registered for the employee.';
                }
                action("Co&nfidential Info. Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&nfidential Info. Overview';
                    Image = ConfidentialOverview;
                    RunObject = Page "Confidential Info. Overview";
                    ToolTip = 'View confidential information that is registered for the employee.';
                }
                separator(Action61)
                {
                }
                action("Online Map")
                {
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        DisplayMap;
                    end;
                }
            }
            group("H&istory")
            {
                Caption = 'H&istory';
                Image = History;
                action("Labor Contract")
                {
                    Caption = 'Labor Contract';
                    Image = Agreement;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Labor Contracts";
                    RunPageLink = "No." = FIELD("Contract No.");
                }
                action("Record of Service")
                {
                    Caption = 'Record of Service';
                    Image = ServiceLines;
                    RunObject = Page "Employee Record of Service";
                    RunPageLink = "No." = FIELD("No.");
                }
                action("Vacation Balance")
                {
                    Caption = 'Vacation Balance';
                    Image = Holiday;
                    RunObject = Page "Employee Accrual Entries";
                    RunPageLink = "Employee No." = FIELD("No.");
                }
                separator(Action1210021)
                {
                }
                action("Employee Job Entries")
                {
                    Caption = 'Employee Job Entries';
                    Image = JobLedger;
                    RunObject = Page "Employee Job Entry";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Employee No.", "Starting Date", "Ending Date");
                }
                action("Employee Absence Entries")
                {
                    Caption = 'Employee Absence Entries';
                    Image = LedgerEntries;
                    RunObject = Page "Employee Absence Entries";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Employee No.", "Time Activity Code", "Entry Type", "Start Date");
                }
                action("Employee Ledger Entries")
                {
                    Caption = 'Employee Ledger Entries';
                    Image = VendorLedger;
                    RunObject = Page "Employee Ledger Entries";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Employee No.", "Element Code", "Action Starting Date");
                    ShortCutKey = 'Ctrl+F7';
                }
                action("Payroll Ledger Entries")
                {
                    Caption = 'Payroll Ledger Entries';
                    Image = LedgerEntries;
                    RunObject = Page "Payroll Ledger Entries";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Employee No.", "Period Code", "Element Code");
                }
                separator(Action1210016)
                {
                }
                action("Vacation Orders")
                {
                    Caption = 'Vacation Orders';
                    Image = Holiday;
                    RunObject = Page "Posted Vacation Orders";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "No.")
                                  WHERE("Document Type" = CONST(Vacation));
                }
                action("Sick Leave Orders")
                {
                    Caption = 'Sick Leave Orders';
                    Image = Absence;
                    RunObject = Page "Posted Sick Leave Orders";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "No.")
                                  WHERE("Document Type" = CONST("Sick Leave"));
                }
                action("Travel Orders")
                {
                    Caption = 'Travel Orders';
                    Image = Travel;
                    RunObject = Page "Posted Travel Orders";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "No.")
                                  WHERE("Document Type" = CONST(Travel));
                }
                action("Other Absences")
                {
                    Caption = 'Other Absences';
                    Image = Absence;
                    RunObject = Page "Posted Other Absence Orders";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "No.")
                                  WHERE("Document Type" = CONST("Other Absence"));
                }
            }
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action(ApplyTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Ellipsis = true;
                    Image = ApplyTemplate;
                    ToolTip = 'Apply a template to update the entity with your standard settings for a certain type of entity.';

                    trigger OnAction()
                    var
                        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
                    begin
                        EmployeeTemplMgt.UpdateEmployeeFromTemplate(Rec);
                    end;
                }
                action(SaveAsTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Save as Template';
                    Ellipsis = true;
                    Image = Save;
                    ToolTip = 'Save the employee card as a template that can be reused to create new employee cards. Employee templates contain preset information to help you fill fields on employee cards.';

                    trigger OnAction()
                    var
                        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
                    begin
                        EmployeeTemplMgt.SaveAsTemplate(Rec);
                    end;
                }
                action("Create Resp. Employee")
                {
                    Caption = 'Create Resp. Employee';
                    Image = PersonInCharge;

                    trigger OnAction()
                    var
                        EmpVendUpdate: Codeunit "EmployeeVendor-Update";
                    begin
                        if Confirm(Text000, true) then
                            EmpVendUpdate.OnInsert(Rec);
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("Personal Account T-54&a")
                {
                    Caption = 'Personal Account T-54&a';
                    Ellipsis = true;
                    Image = "Report";
                    RunPageOnRec = true;

                    trigger OnAction()
                    begin
                        Employee := Rec;
                        Employee.SetRecFilter;
                        REPORT.RunModal(REPORT::"Personal Account T-54a", true, true, Employee);
                    end;
                }
                action("&Employee Card T-2")
                {
                    Caption = '&Employee Card T-2';
                    Ellipsis = true;
                    Image = "Report";

                    trigger OnAction()
                    begin
                        Employee := Rec;
                        Employee.SetRecFilter;
                        REPORT.RunModal(REPORT::"Employee Card T-2", true, true, Employee);
                    end;
                }
                action("HR Generic Report")
                {
                    Caption = 'HR Generic Report';
                    Image = "Report";

                    trigger OnAction()
                    var
                        Employee: Record Employee;
                    begin
                        Employee := Rec;
                        Employee.SetRecFilter;
                        REPORT.RunModal(REPORT::"HR Generic Report", true, true, Employee);
                    end;
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal;
                    end;
                }
                action(Contact)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Image = ContactPerson;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ToolTip = 'View or edit detailed information about the contact person at the employee.';

                    trigger OnAction()
                    var
                        ContBusRel: Record "Contact Business Relation";
                        Contact: Record Contact;
                    begin
                        if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Employee, "No.") then begin
                            Contact.Get(ContBusRel."Contact No.");
                            Page.Run(Page::"Contact Card", Contact);
                        end;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed then
            if "No." = '' then
                if DocumentNoVisibility.EmployeeNoSeriesIsDefault() then
                    NewMode := true;
    end;

    trigger OnAfterGetCurrRecord()
    var
        NewEmployee: Record Employee;
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
    begin
        if not NewMode then
            exit;
        NewMode := false;

        if EmployeeTemplMgt.InsertEmployeeFromTemplate(NewEmployee) then begin
            Copy(NewEmployee);
            CurrPage.Update();
        end else
            if EmployeeTemplMgt.TemplatesAreNotEmpty() then
                CurrPage.Close();
    end;

    var
        Employee: Record Employee;
        StaffingList: Record "Staff List";
        CustomizedCalendar: Record "Customized Calendar Change";
        CustomizedCalEntry: Record "Customized Calendar Entry";
        Text000: Label 'Do you want to create Resp. Employee?';
        CalendarMgmt: Codeunit "Calendar Management";
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
        NewMode: Boolean;
}

