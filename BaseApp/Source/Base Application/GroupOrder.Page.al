page 17374 "Group Order"
{
    Caption = 'Group Order';
    PageType = Document;
    SourceTable = "Group Order Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
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
            }
            part(Subform; "Group Order Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                separator(Action1210018)
                {
                }
                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = Approve;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Approve Group Order", Rec);
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
                begin
                    PrintOrder(Rec);
                end;
            }
        }
    }
}

