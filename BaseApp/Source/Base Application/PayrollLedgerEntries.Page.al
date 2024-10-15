page 17420 "Payroll Ledger Entries"
{
    Caption = 'Payroll Ledger Entries';
    DataCaptionFields = "Element Code";
    Editable = false;
    PageType = List;
    SourceTable = "Payroll Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; "Entry No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Element Type"; "Element Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the related payroll element for tax registration purposes.';
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description associated with this line.';
                    Visible = true;
                }
                field("Directory Code"; "Directory Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Posting Type"; "Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Calculate Priority"; "Calculate Priority")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Calc Group"; "Calc Group")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Payroll Amount"; "Payroll Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Taxable Amount"; "Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field("Payment Days"; "Payment Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Employee Payroll Account No."; "Employee Payroll Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Code KPP"; "Code KPP")
                {
                    Visible = false;
                }
                field("Code OKATO"; "Code OKATO")
                {
                    Visible = false;
                }
                field("Future Period Vacation Posted"; "Future Period Vacation Posted")
                {
                    Visible = false;
                }
                field("Insurance Fee Category Code"; "Insurance Fee Category Code")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("E&ntry")
            {
                Caption = 'E&ntry';
                Image = Entry;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                separator(Action1210008)
                {
                }
                action("Detailed Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed Ledger Entries';
                    Image = View;
                    RunObject = Page "Dtld. Payroll Ledger Entries";
                    RunPageLink = "Payroll Ledger Entry No." = FIELD("Entry No.");
                }
                action("Base Amount Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Amount Entries';
                    Image = Entries;
                    RunObject = Page "Payroll Base Amount Entries";
                    RunPageLink = "Entry No." = FIELD("Entry No.");
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    NavigateForm.SetDoc("Posting Date", "Document No.");
                    NavigateForm.Run;
                end;
            }
        }
    }

    var
        NavigateForm: Page Navigate;
}

