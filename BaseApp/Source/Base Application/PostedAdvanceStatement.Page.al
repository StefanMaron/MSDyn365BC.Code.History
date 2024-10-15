page 12433 "Posted Advance Statement"
{
    Caption = 'Posted Advance Statement';
    Editable = false;
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Purch. Inv. Header";
    SourceTableView = WHERE("Empl. Purchase" = CONST(true));

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
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Advance Purpose"; "Advance Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the purpose of the advance associated with this header.';
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Pre-Assigned No."; "Pre-Assigned No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Vendor Invoice No."; "Vendor Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
            part(PurchInvLines; "Posted Adv. Statement Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Statement)
            {
                Caption = 'Statement';
                field("No. of Documents"; "No. of Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of documents associated with this header.';
                }
                field("No. of Pages"; "No. of Pages")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of pages of this header.';
                }
                field("Remaining/Overdraft Doc. No."; "Remaining/Overdraft Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the remaining or overdraft document number associated with this header.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the record.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            "Currency Factor" := ChangeExchangeRate.GetParameter;
                            Modify;
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Advance")
            {
                Caption = '&Advance';
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Purchase Invoice Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Invoice"),
                                  "No." = FIELD("No.");
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
            }
        }
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
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    PurchInvHeader.Copy(Rec);
                    CurrPage.SetSelectionFilter(PurchInvHeader);
                    PurchInvHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    var
        PurchInvHeader: Record "Purch. Inv. Header";
        ChangeExchangeRate: Page "Change Exchange Rate";
}

