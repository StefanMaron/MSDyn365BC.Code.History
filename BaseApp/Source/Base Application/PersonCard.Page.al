page 17350 "Person Card"
{
    Caption = 'Person Card';
    PageType = Card;
    SourceTable = Person;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Middle Name"; "Middle Name")
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
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
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
                field("Identity Document Type"; "Identity Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Non-Resident"; "Non-Resident")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor that is associated with the person.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
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
                field(Nationality; Nationality)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Native Language"; "Native Language")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Citizenship; Citizenship)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Citizenship Country/Region"; "Citizenship Country/Region")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sick Leave Payment Benefit"; "Sick Leave Payment Benefit")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Birthplace Type"; "Birthplace Type")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Military Service")
            {
                Caption = 'Military Service';
                field("Military Status"; "Military Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Militaty Duty Relation"; "Militaty Duty Relation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Rank"; "Military Rank")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Speciality No."; "Military Speciality No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Agency"; "Military Agency")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Retirement Category"; "Military Retirement Category")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Structure"; "Military Structure")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Special Military Register"; "Special Military Register")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Registration Office"; "Military Registration Office")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Registration No."; "Military Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Fitness"; "Military Fitness")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Recruit; Recruit)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Reservist; Reservist)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Mobilisation Order"; "Mobilisation Order")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Dismissal Reason"; "Military Dismissal Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Military Dismissal Date"; "Military Dismissal Date")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Record of Service")
            {
                Caption = 'Record of Service';
                field("Total Service (Days)"; "Total Service (Days)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Total Service (Months)"; "Total Service (Months)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Total Service (Years)"; "Total Service (Years)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insured Service (Days)"; "Insured Service (Days)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insured Service (Months)"; "Insured Service (Months)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Insured Service (Years)"; "Insured Service (Years)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unbroken Service (Days)"; "Unbroken Service (Days)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unbroken Service (Months)"; "Unbroken Service (Months)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unbroken Service (Years)"; "Unbroken Service (Years)")
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
                    Image = Employee;
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
                separator(Action1210083)
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
                action("Change Name History")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Name History';
                    Image = Change;
                    RunObject = Page "Person Name History";
                    RunPageLink = "Person No." = FIELD("No.");
                }
                separator(Action1210112)
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Vendor")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Vendor';
                    Image = Vendor;

                    trigger OnAction()
                    begin
                        PersonVendorUpdate.CreateVendor(Rec);
                    end;
                }
                action("Change Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Name';
                    Ellipsis = true;
                    Image = Change;

                    trigger OnAction()
                    var
                        ChangePersonName: Report "Change Person Name";
                    begin
                        ChangePersonName.SetPerson(Rec);
                        ChangePersonName.RunModal;
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("HR Generic Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'HR Generic Report';
                    Image = "Report";

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
                    RunPageOnRec = true;

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
    }

    var
        PersonVendorUpdate: Codeunit "Person\Vendor Update";
}

