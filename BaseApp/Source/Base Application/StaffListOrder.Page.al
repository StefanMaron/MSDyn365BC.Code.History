page 17385 "Staff List Order"
{
    Caption = 'Staff List Order';
    PageType = Document;
    SourceTable = "Staff List Order Header";

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
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
                field("Chief Accountant No."; "Chief Accountant No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            part(Lines; "Staff List Order Subf")
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
                    RunPageLink = "Table Name" = CONST("SL Order"),
                                  "No." = FIELD("No."),
                                  "Line No." = CONST(0);
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';

                    trigger OnAction()
                    var
                        ReleaseOrder: Codeunit "Release Staff List Order";
                    begin
                        CODEUNIT.Run(CODEUNIT::"Release Staff List Order", Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    var
                        ReleaseOrder: Codeunit "Release Staff List Order";
                    begin
                        ReleaseOrder.Reopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Staff List Order-Post (Y/N)", Rec);
                    end;
                }
            }
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
                    HROrderPrint: Codeunit "HR Order - Print";
                begin
                    HROrderPrint.PrintFormT3a(Rec, false);
                end;
            }
        }
    }
}

