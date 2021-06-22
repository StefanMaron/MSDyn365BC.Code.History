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
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        AssistEdit;
                    end;
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the employee''s first name.';
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee''s middle name.';
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = BasicHR;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the employee''s last name.';
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee''s job title.';
                }
                field(Initials; Initials)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s initials.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field(Gender; Gender)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s gender.';
                }
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Company Phone No.';
                    ToolTip = 'Specifies the employee''s telephone number.';
                }
                field("Company E-Mail"; "Company E-Mail")
                {
                    ApplicationArea = BasicHR;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the employee''s email address at the company.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = BasicHR;
                    Importance = Additional;
                    ToolTip = 'Specifies when this record was last modified.';
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = BasicHR;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
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
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = BasicHR;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the employee''s address on your preferred online map.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update(true);
                            DisplayMap;
                        end;
                    }
                }
                group(Control7)
                {
                    ShowCaption = false;
                    field("Mobile Phone No."; "Mobile Phone No.")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Private Phone No.';
                        Importance = Promoted;
                        ToolTip = 'Specifies the employee''s private telephone number.';
                    }
                    field(Pager; Pager)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the employee''s pager number.';
                    }
                    field(Extension; Extension)
                    {
                        ApplicationArea = BasicHR;
                        Importance = Promoted;
                        ToolTip = 'Specifies the employee''s telephone extension.';
                    }
                    field("Phone No."; "Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Direct Phone No.';
                        Importance = Promoted;
                        ToolTip = 'Specifies the employee''s telephone number.';
                    }
                    field("E-Mail"; "E-Mail")
                    {
                        ApplicationArea = BasicHR;
                        Caption = 'Private Email';
                        Importance = Promoted;
                        ToolTip = 'Specifies the employee''s private email address.';
                    }
                    field("Alt. Address Code"; "Alt. Address Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies a code for an alternate address.';
                    }
                    field("Alt. Address Start Date"; "Alt. Address Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the starting date when the alternate address is valid.';
                    }
                    field("Alt. Address End Date"; "Alt. Address End Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the last day when the alternate address is valid.';
                    }
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
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a resource number for the employee.';
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a salesperson or purchaser code for the employee.';
                }
            }
            group(Personal)
            {
                Caption = 'Personal';
                field("Birth Date"; "Birth Date")
                {
                    ApplicationArea = BasicHR;
                    Importance = Promoted;
                    ToolTip = 'Specifies the employee''s date of birth.';
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
            group(Payments)
            {
                Caption = 'Payments';
                field("Employee Posting Group"; "Employee Posting Group")
                {
                    ApplicationArea = BasicHR;
                    LookupPageID = "Employee Posting Groups";
                    ToolTip = 'Specifies the employee''s type to link business transactions made for the employee with the appropriate account in the general ledger.';
                }
                field("Application Method"; "Application Method")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies how to apply payments to entries for this employee.';
                }
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a number of the bank branch.';
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
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the bank where the employee has the account.';
                }
            }
        }
        area(factboxes)
        {
            part(Control3; "Employee Picture")
            {
                ApplicationArea = BasicHR;
                SubPageLink = "No." = FIELD("No.");
            }
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
                    RunPageLink = "Employee No." = FIELD("No.");
                    ToolTip = 'Open the list of addresses that are registered for the employee.';
                }
                action("&Relatives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Relatives';
                    Image = Relatives;
                    RunObject = Page "Employee Relatives";
                    RunPageLink = "Employee No." = FIELD("No.");
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
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Confidential Information";
                    RunPageLink = "Employee No." = FIELD("No.");
                    ToolTip = 'Open the list of any confidential information that is registered for the employee.';
                }
                action("Q&ualifications")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Q&ualifications';
                    Image = Certificate;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Employee Qualifications";
                    RunPageLink = "Employee No." = FIELD("No.");
                    ToolTip = 'Open the list of qualifications that are registered for the employee.';
                }
                action("A&bsences")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'A&bsences';
                    Image = Absence;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Employee Absences";
                    RunPageLink = "Employee No." = FIELD("No.");
                    ToolTip = 'View absence information for the employee.';
                }
                separator(Action23)
                {
                }
                action("Absences by Ca&tegories")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Absences by Ca&tegories';
                    Image = AbsenceCategory;
                    RunObject = Page "Empl. Absences by Categories";
                    RunPageLink = "No." = FIELD("No."),
                                  "Employee No. Filter" = FIELD("No.");
                    ToolTip = 'View categorized absence information for the employee.';
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
                action("Ledger E&ntries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Ledger E&ntries';
                    Image = VendorLedger;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Employee Ledger Entries";
                    RunPageLink = "Employee No." = FIELD("No.");
                    RunPageView = SORTING("Employee No.")
                                  ORDER(Descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
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
                action(PayEmployee)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Pay Employee';
                    Image = SuggestVendorPayments;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Employee Ledger Entries";
                    RunPageLink = "Employee No." = FIELD("No."),
                                  "Remaining Amount" = FILTER(< 0),
                                  "Applies-to ID" = FILTER('');
                    ToolTip = 'View employee ledger entries for the record with remaining amount that have not been paid yet.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetNoFieldVisible;
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;

    var
        ShowMapLbl: Label 'Show on Map';
        FormatAddress: Codeunit "Format Address";
        NoFieldVisible: Boolean;
        IsCountyVisible: Boolean;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.EmployeeNoIsVisible;
    end;
}

