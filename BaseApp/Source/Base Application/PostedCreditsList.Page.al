page 31059 "Posted Credits List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Credits';
    CardPageID = "Posted Credit Card";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Credit Header";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1220006)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the credit card.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for credit card.';
                }
                field("Company No."; "Company No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customer or vendor.';
                }
                field("Company City"; "Company City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of customer or vendor.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Balance (LCY)"; "Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the balance on this credit card.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220011; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1220010; Notes)
            {
                ApplicationArea = Notes;
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PostedCreditHdr: Record "Posted Credit Header";
                begin
                    PostedCreditHdr := Rec;
                    CurrPage.SetSelectionFilter(PostedCreditHdr);
                    PostedCreditHdr.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;
}

