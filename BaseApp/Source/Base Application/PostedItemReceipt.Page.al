page 12457 "Posted Item Receipt"
{
    Caption = 'Posted Item Receipt';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Item Receipt Header";

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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
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
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                }
                field(Correction; Correction)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry as a corrective entry. You can use the field if you need to post a corrective entry to an account.';
                }
            }
            part(ReceiptLines; "Posted Item Receipt Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Control1900309501)
            {
                Caption = 'Dimensions';
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many pieces of the item are processed.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total number of parcels in the document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the net weight of the item. You may need the net weight to complete customs documents, waybills, and other forms.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight, including the weight of any packaging, of the catalog item.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total volume of the items in the document.';
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
            group("&Receipt")
            {
                Caption = '&Receipt';
                Image = Receipt;
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Inventory Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Item Receipt"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.Update;
                    end;
                }
                action("Employee Si&gnatures")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Si&gnatures';
                    Image = Signature;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Posted Document Signatures";
                    RunPageLink = "Table ID" = CONST(12451),
                                  "Document No." = FIELD("No.");
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
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    ItemRcptHeader: Record "Item Receipt Header";
                begin
                    CurrPage.SetSelectionFilter(ItemRcptHeader);
                    ItemRcptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcTotals;
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;

    [Scope('OnPrem')]
    procedure CalcTotals()
    var
        ItemRcptLine: Record "Item Receipt Line";
    begin
        ClearAll;

        ItemRcptLine.SetRange("Document No.", "No.");
        if ItemRcptLine.Find('-') then
            repeat
                LineQty := LineQty + ItemRcptLine.Quantity;
                TotalNetWeight :=
                  TotalNetWeight + (ItemRcptLine.Quantity * ItemRcptLine."Net Weight");
                TotalGrossWeight :=
                  TotalGrossWeight + (ItemRcptLine.Quantity * ItemRcptLine."Gross Weight");
                TotalVolume :=
                  TotalVolume + (ItemRcptLine.Quantity * ItemRcptLine."Unit Volume");
                if ItemRcptLine."Units per Parcel" > 0 then
                    TotalParcels :=
                      TotalParcels +
                      Round(ItemRcptLine.Quantity / ItemRcptLine."Units per Parcel", 1, '>');
            until ItemRcptLine.Next = 0;
    end;
}

