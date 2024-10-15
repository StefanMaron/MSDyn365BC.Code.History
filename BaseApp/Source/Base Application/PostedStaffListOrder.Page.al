page 17396 "Posted Staff List Order"
{
    Caption = 'Posted Staff List Order';
    Editable = false;
    PageType = Document;
    SourceTable = "Posted Staff List Order Header";

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
                }
                field("HR Manager No."; "HR Manager No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("HR Order No."; "HR Order No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("HR Order Date"; "HR Order Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Chief Accountant No."; "Chief Accountant No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            part(Lines; "Posted Staff List Order Subf")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "HR Order Comment Lines";
                    RunPageLink = "Table Name" = CONST("P.SL Order"),
                                  "No." = FIELD("No."),
                                  "Line No." = CONST(0);
                }
            }
        }
        area(processing)
        {
            action("P&rint")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'P&rint';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    StaffListOrderHeader: Record "Staff List Order Header";
                    HROrderPrint: Codeunit "HR Order - Print";
                begin
                    StaffListOrderHeader.TransferFields(Rec);
                    HROrderPrint.PrintFormT3a(StaffListOrderHeader, true);
                end;
            }
        }
    }
}

