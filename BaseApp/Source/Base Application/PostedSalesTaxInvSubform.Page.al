page 28072 "Posted Sales Tax Inv. Subform"
{
    AutoSplitKey = true;
    Caption = 'Posted Sales Tax Inv. Subform';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Sales Tax Invoice Line";

    layout
    {
        area(content)
        {
            repeater(Control1500000)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the document.';
                }
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the value on the original document.';
                }
                field("Paid Amount Incl. VAT"; "Paid Amount Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that is applicable to a particular line. It is calculated during the posting of a tax invoice.';
                }
                field("Paid VAT"; "Paid VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount paid in VAT for the line.';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job that the entry is for.';
                    Visible = false;
                }
                field("Appl.-to Job Entry"; "Appl.-to Job Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field("Apply and Close (Job)"; "Apply and Close (Job)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value on the original document.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code with which the document is associated.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code with which the document is associated.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                action("&Posted Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Posted Invoice';
                    ToolTip = 'View the original invoice that the tax invoice applies to.';

                    trigger OnAction()
                    begin
                        ShowSalesInvoice;
                    end;
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure ShowSalesInvoice()
    begin
        ShowSalesInvoice1;
    end;
}

