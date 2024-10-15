page 17395 "Employee Ledger Entries"
{
    Caption = 'Employee Ledger Entries';
    DataCaptionFields = "Employee No.";
    Editable = false;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Employee Ledger Entry";
    UsageCategory = History;
    AdditionalSearchTerms = 'Employee Check, Employee Expense, Pay Employee';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Employee No."; "Employee No.")
                {
                    ToolTip = 'Specifies the number of the involved employee.';
                    Visible = false;
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Action Starting Date"; "Action Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity that the expense represents.';
                }
                field("Action Ending Date"; "Action Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity that the expense represents.';
                    Visible = true;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Payment Days"; "Payment Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Percent"; "Payment Percent")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Source"; "Payment Source")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Days Not Paid"; "Days Not Paid")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Calendar Code"; "Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related work calendar. ';
                }
                field("Payroll Calc Group"; "Payroll Calc Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Position No."; "Position No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Shift+Ctrl+I';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    NavigateForm.SetDoc("Document Date", "Document No.");
                    NavigateForm.Run;
                end;
            }
        }
    }

    var
        NavigateForm: Page Navigate;
}

