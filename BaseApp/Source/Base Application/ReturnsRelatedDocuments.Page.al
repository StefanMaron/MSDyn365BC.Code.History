page 6670 "Returns-Related Documents"
{
    Caption = 'Returns-Related Documents';
    PageType = List;
    SourceTable = "Returns-Related Document";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        PurchHeader: Record "Purchase Header";
                    begin
                        Clear(CopyDocMgt);
                        case "Document Type" of
                            "Document Type"::"Sales Order":
                                SalesHeader.Get(SalesHeader."Document Type"::Order, "No.");
                            "Document Type"::"Sales Invoice":
                                SalesHeader.Get(SalesHeader."Document Type"::Invoice, "No.");
                            "Document Type"::"Sales Return Order":
                                SalesHeader.Get(SalesHeader."Document Type"::"Return Order", "No.");
                            "Document Type"::"Sales Credit Memo":
                                SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", "No.");
                            "Document Type"::"Purchase Order":
                                PurchHeader.Get(PurchHeader."Document Type"::Order, "No.");
                            "Document Type"::"Purchase Invoice":
                                PurchHeader.Get(PurchHeader."Document Type"::Invoice, "No.");
                            "Document Type"::"Purchase Return Order":
                                PurchHeader.Get(PurchHeader."Document Type"::"Return Order", "No.");
                            "Document Type"::"Purchase Credit Memo":
                                PurchHeader.Get(PurchHeader."Document Type"::"Credit Memo", "No.");
                        end;

                        if "Document Type" in ["Document Type"::"Sales Order" .. "Document Type"::"Sales Credit Memo"] then
                            CopyDocMgt.ShowSalesDoc(SalesHeader)
                        else
                            CopyDocMgt.ShowPurchDoc(PurchHeader);
                    end;
                }
            }
        }
    }

    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
}

