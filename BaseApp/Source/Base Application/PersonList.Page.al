page 17351 "Person List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Persons';
    CardPageID = "Person Card";
    Editable = false;
    PageType = List;
    SourceTable = Person;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("Mobile Phone No."; "Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the person''s email address.';
                }
                field("Birth Date"; "Birth Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Social Security No."; "Social Security No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the person''s VAT registration number. ';
                }
                field("Tax Inspection Code"; "Tax Inspection Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Gender; Gender)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Single Parent"; "Single Parent")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Family Status"; "Family Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Citizenship; Citizenship)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Nationality; Nationality)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Native Language"; "Native Language")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Person)
            {
                Caption = 'Person';
                Image = User;
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Person),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Addresses)
                {
                    Caption = 'Addresses';
                    Image = Addresses;
                    RunObject = Page "Alternative Address List";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                action(Documents)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Documents';
                    Image = Documents;
                    RunObject = Page "Person Documents";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                action("&Photo")
                {
                    Caption = '&Photo';
                    Image = Picture;
                    RunObject = Page "Employee Picture";
                    RunPageLink = "No." = FIELD("No.");
                }
                action(Employees)
                {
                    Caption = 'Employees';
                    Image = TeamSales;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Employee List";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                action(Relatives)
                {
                    Caption = 'Relatives';
                    Image = Relatives;
                    RunObject = Page "Employee Relatives";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                action(Languages)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Languages';
                    Image = Language;
                    RunObject = Page "Employee Language";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                action("Medical Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Medical Information';
                    Image = List;
                    RunObject = Page "Person Medical Information";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                action(Qualification)
                {
                    Caption = 'Qualification';
                    Image = QualificationOverview;
                    RunObject = Page "Employee Qualifications";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                separator(Action1210045)
                {
                }
                action("Labor Contracts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Labor Contracts';
                    Image = Agreement;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Labor Contracts";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                action("Previous Job History")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Previous Job History';
                    Image = History;
                    RunObject = Page "Person Job History";
                    RunPageLink = "Person No." = FIELD("No.");
                    ShortCutKey = 'Ctrl+F7';
                }
                action("Taxable Income")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Taxable Income';
                    Image = Payment;
                    RunObject = Page "Person Income";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                action("Income for FSI")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Income for FSI';
                    Image = Payment;
                    RunObject = Page "Person Income FSI";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                separator(Action1210056)
                {
                }
                action("Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contract Terms';
                    Image = CheckList;
                    RunObject = Page "Labor Contract Terms Setup";
                    RunPageLink = "Table Type" = CONST(Person),
                                  "No." = FIELD("No.");
                }
            }
        }
        area(processing)
        {
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("HR Generic Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'HR Generic Report';
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = "Report";
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        Person: Record Person;
                    begin
                        Person := Rec;
                        Person.SetRecFilter;
                        REPORT.RunModal(REPORT::"HR Generic Report", true, true, Person);
                    end;
                }
                action("Salary Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Salary Reference';
                    Image = "Report";

                    trigger OnAction()
                    var
                        Person: Record Person;
                    begin
                        Person := Rec;
                        Person.SetRecFilter;
                        REPORT.RunModal(REPORT::"Salary Reference", true, false, Person);
                    end;
                }
            }
        }
        area(reporting)
        {
        }
    }
}

