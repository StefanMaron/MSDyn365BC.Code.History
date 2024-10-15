page 5201 "Employee List"
{
    ApplicationArea = BasicHR;
    Caption = 'Employees';
    CardPageID = "Employee Card";
    Editable = false;
    PageType = List;
    SourceTable = Employee;
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
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(FullName; GetFullName)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of the employee.';
                    Visible = false;
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = BasicHR;
                    NotBlank = true;
                    ToolTip = 'Specifies the employee''s first name.';
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee''s middle name.';
                    Visible = false;
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = BasicHR;
                    NotBlank = true;
                    ToolTip = 'Specifies the employee''s last name.';
                }
                field(Initials; Initials)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee''s initials.';
                    Visible = false;
                }
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee''s job title.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Company Phone No.';
                    ToolTip = 'Specifies the employee''s telephone number.';
                }
                field(Extension; Extension)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee''s telephone extension.';
                    Visible = false;
                }
                field("Mobile Phone No."; "Mobile Phone No.")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Private Phone No.';
                    ToolTip = 'Specifies the employee''s private telephone number.';
                    Visible = false;
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Private Email';
                    ToolTip = 'Specifies the employee''s private email address.';
                    Visible = false;
                }
                field("Statistics Group Code"; "Statistics Group Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a statistics group code to assign to the employee for statistical purposes.';
                    Visible = false;
                }
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a resource number for the employee.';
                    Visible = false;
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies if a comment has been entered for this entry.';
                }
            }
        }
        area(factboxes)
        {
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
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Employee),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(5200),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Employee: Record Employee;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Employee);
                            DefaultDimMultiple.SetMultiRecord(Employee, FieldNo("No."));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
                action("&Picture")
                {
                    ApplicationArea = BasicHR;
                    Caption = '&Picture';
                    Image = Picture;
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
                action("Co&nfidential Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&nfidential Information';
                    Image = Lock;
                    RunObject = Page "Confidential Information";
                    RunPageLink = "Employee No." = FIELD("No.");
                    ToolTip = 'Open the list of any confidential information that is registered for the employee.';
                }
                separator(Action1210022)
                {
                }
                action("A&bsence Orders")
                {
                    Caption = 'A&bsence Orders';
                    Image = OrderTracking;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Absence Order List";
                    RunPageLink = "Employee No." = FIELD("No.");
                }
                action(Timesheets)
                {
                    Caption = 'Timesheets';
                    Image = PeriodStatus;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Timesheet Status";
                    RunPageLink = "Employee No." = FIELD("No.");
                }
                separator(Action1210025)
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Q&ualifications';
                    Image = Certificate;
                    RunObject = Page "Employee Qualifications";
                    RunPageLink = "Person No." = FIELD("Person No.");
                    ToolTip = 'Open the list of qualifications that are registered for the employee.';
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
                separator(Action51)
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
                action("Con&fidential Info. Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Con&fidential Info. Overview';
                    Image = ConfidentialOverview;
                    RunObject = Page "Confidential Info. Overview";
                    ToolTip = 'View confidential information that is registered for the employee.';
                }
                action(Contact)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Image = ContactPerson;
                    Promoted = true;
                    PromotedCategory = Process;
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
                separator(Action1210035)
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
                separator(Action1210046)
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
                separator(Action1210051)
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
            action("Employee Journal")
            {
                Caption = 'Employee Journal';
                Image = OpenJournal;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Employee Journal";
                RunPageLink = "Employee No." = FIELD("No.");
            }
        }
        area(reporting)
        {
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Create Resp. Employee")
                {
                    Caption = 'Create Resp. Employee';
                    Image = PersonInCharge;

                    trigger OnAction()
                    var
                        EmpVendUpdate: Codeunit "EmployeeVendor-Update";
                    begin
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
                    var
                        Employee: Record Employee;
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
                    Promoted = true;
                    PromotedCategory = "Report";
                    ToolTip = 'Print the employee card T-2.';

                    trigger OnAction()
                    var
                        Employee: Record Employee;
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
                    Promoted = true;
                    PromotedCategory = "Report";
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        Employee: Record Employee;
                    begin
                        Employee := Rec;
                        Employee.SetRecFilter;
                        REPORT.RunModal(REPORT::"HR Generic Report", true, true, Employee);
                    end;
                }
            }
            action(ApplyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Apply Template';
                Ellipsis = true;
                Image = ApplyTemplate;
                ToolTip = 'Apply a template to update one or more entities with your standard settings for a certain type of entity.';

                trigger OnAction()
                var
                    Employee: Record Employee;
                    EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
                begin
                    CurrPage.SetSelectionFilter(Employee);
                    EmployeeTemplMgt.UpdateEmployeesFromTemplate(Employee);
                end;
            }
        }
    }

    [Scope('OnPrem')]
    procedure GetSelectionFilter(): Text
    var
        Employee: Record Employee;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Employee);
        exit(SelectionFilterManagement.GetSelectionFilterForEmployee(Employee));
    end;

    [Scope('OnPrem')]
    procedure SetSelection(var Employee: Record Employee)
    begin
        CurrPage.SetSelectionFilter(Employee);
    end;
}