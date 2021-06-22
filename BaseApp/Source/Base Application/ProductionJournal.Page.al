page 5510 "Production Journal"
{
    Caption = 'Production Journal';
    DataCaptionExpression = GetCaption;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Post/Print,Line,Prod. Order';
    SourceTable = "Item Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PostingDate; PostingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies a posting date that will apply to all the lines in the production journal.';

                    trigger OnValidate()
                    begin
                        PostingDateOnAfterValidate;
                    end;
                }
                field(FlushingFilter; FlushingFilter)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Flushing Method Filter';
                    OptionCaption = 'Manual,Forward,Backward,Pick + Forward,Pick + Backward,All Methods';
                    ToolTip = 'Specifies which components to view and handle in the journal, according to their flushing method.';

                    trigger OnValidate()
                    begin
                        FlushingFilterOnAfterValidate;
                    end;
                }
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the type of transaction that will be posted from the item journal line.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the posting date for the entry.';
                    Visible = false;
                }
                field("Order Line No."; "Order Line No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the line number of the order that created the entry.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies a document number for the journal line.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the number of the item on the journal line.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if Item.Get("Item No.") then
                            PAGE.RunModal(PAGE::"Item List", Item);
                    end;
                }
                field("Operation No."; "Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the number of the production operation on the item journal line when the journal functions as an output journal.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Manufacturing;
                    OptionCaption = 'Work Center,Machine Center, ';
                    ToolTip = 'Specifies the journal type, which is either Work Center or Machine Center.';
                    Visible = true;
                }
                field("Flushing Method"; "Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies a description of the item on the journal line.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Consumption Quantity';
                    Editable = QuantityEditable;
                    HideValue = QuantityHideValue;
                    ToolTip = 'Specifies the quantity of the component that will be posted as consumed.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the inventory location where the item on the journal line will be registered.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Work Shift Code"; "Work Shift Code")
                {
                    ApplicationArea = Manufacturing;
                    Editable = WorkShiftCodeEditable;
                    ToolTip = 'Specifies the work shift code for this Journal line.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    Editable = StartingTimeEditable;
                    ToolTip = 'Specifies the starting time of the operation on the item journal line.';
                    Visible = false;
                }
                field("Ending Time"; "Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    Editable = EndingTimeEditable;
                    ToolTip = 'Specifies the ending time of the operation on the item journal line.';
                    Visible = false;
                }
                field("Concurrent Capacity"; "Concurrent Capacity")
                {
                    ApplicationArea = Manufacturing;
                    Editable = ConcurrentCapacityEditable;
                    ToolTip = 'Specifies the concurrent capacity.';
                    Visible = false;
                }
                field("Setup Time"; "Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    Editable = SetupTimeEditable;
                    HideValue = SetupTimeHideValue;
                    ToolTip = 'Specifies the time required to set up the machines for this journal line.';
                }
                field("Run Time"; "Run Time")
                {
                    ApplicationArea = Manufacturing;
                    Editable = RunTimeEditable;
                    HideValue = RunTimeHideValue;
                    ToolTip = 'Specifies the run time of the operations represented by this journal line.';
                }
                field("Cap. Unit of Measure Code"; "Cap. Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    Editable = CapUnitofMeasureCodeEditable;
                    ToolTip = 'Specifies the unit of measure code for the capacity usage.';
                    Visible = false;
                }
                field("Scrap Code"; "Scrap Code")
                {
                    ApplicationArea = Manufacturing;
                    Editable = ScrapCodeEditable;
                    ToolTip = 'Specifies why an item has been scrapped.';
                    Visible = false;
                }
                field("Output Quantity"; "Output Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Editable = OutputQuantityEditable;
                    HideValue = OutputQuantityHideValue;
                    ToolTip = 'Specifies the quantity of the produced item that can be posted as output on the journal line.';
                }
                field("Scrap Quantity"; "Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Editable = ScrapQuantityEditable;
                    HideValue = ScrapQuantityHideValue;
                    ToolTip = 'Specifies the number of units produced incorrectly, and therefore cannot be used.';
                }
                field(Finished; Finished)
                {
                    ApplicationArea = Manufacturing;
                    Editable = FinishedEditable;
                    ToolTip = 'Specifies that the operation represented by the output journal line is finished.';
                }
                field("Applies-to Entry"; "Applies-to Entry")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the quantity on the journal line must be applied to an already-posted entry. In that case, enter the entry number that the quantity will be applied to.';
                    Visible = false;
                }
                field("Applies-from Entry"; "Applies-from Entry")
                {
                    ApplicationArea = Manufacturing;
                    Editable = AppliesFromEntryEditable;
                    ToolTip = 'Specifies the number of the outbound item ledger entry, whose cost is forwarded to the inbound item ledger entry.';
                    Visible = false;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible2;
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 3);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 4);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 5);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 6);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 7);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 8);
                    end;
                }
            }
            group(Actual)
            {
                Caption = 'Actual';
                fixed(Control1902114901)
                {
                    ShowCaption = false;
                    group("Consump. Qty.")
                    {
                        Caption = 'Consump. Qty.';
                        field(ActualConsumpQty; ActualConsumpQty)
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            HideValue = ActualConsumpQtyHideValue;
                            ShowCaption = false;
                        }
                    }
                    group(Control1901741901)
                    {
                        Caption = 'Setup Time';
                        field(ActualSetupTime; ActualSetupTime)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Setup Time';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            HideValue = ActualSetupTimeHideValue;
                            ToolTip = 'Specifies the time required to set up the machines for this journal line. Setup time is the time it takes to prepare a machine or work center to perform an operation. Each operation can have a different setup time.';
                        }
                    }
                    group(Control1902759401)
                    {
                        Caption = 'Run Time';
                        field(ActualRunTime; ActualRunTime)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Run Time';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            HideValue = ActualRunTimeHideValue;
                            ToolTip = 'Specifies the run time of the operations represented by this journal line. Run time is the time it takes to complete an operation. Run time does not include setup time.';
                        }
                    }
                    group("Output Qty.")
                    {
                        Caption = 'Output Qty.';
                        field(ActualOutputQty; ActualOutputQty)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Output Qty.';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            HideValue = ActualOutputQtyHideValue;
                            ToolTip = 'Specifies the quantity of the produced item that can be posted as output on the journal line. Note that only the output quantity on the last journal line of entry type Output will adjust the inventory level when posting the journal.';
                        }
                    }
                    group("Scrap Qty.")
                    {
                        Caption = 'Scrap Qty.';
                        field(ActualScrapQty; ActualScrapQty)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Scrap Qty.';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            HideValue = ActualScrapQtyHideValue;
                            ToolTip = 'Specifies the number of units of the item that were produced incorrectly and therefore cannot be used. Even if the item number is later changed, this figure will remain on the line.';
                        }
                    }
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
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines(false);
                    end;
                }
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = FIELD("Location Code"),
                                  "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code");
                    RunPageView = SORTING("Location Code", "Bin Code", "Item No.", "Variant Code");
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
                }
            }
            group("Pro&d. Order")
            {
                Caption = 'Pro&d. Order';
                Image = "Order";
                action(Card)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Released Production Order";
                    RunPageLink = "No." = FIELD("Order No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                group("Ledger E&ntries")
                {
                    Caption = 'Ledger E&ntries';
                    Image = Entries;
                    action("Item Ledger E&ntries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Item Ledger E&ntries';
                        Image = ItemLedger;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Order Type" = CONST(Production),
                                      "Order No." = FIELD("Order No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                    }
                    action("Capacity Ledger Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Ledger Entries';
                        Image = CapacityLedger;
                        RunObject = Page "Capacity Ledger Entries";
                        RunPageLink = "Order Type" = CONST(Production),
                                      "Order No." = FIELD("Order No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Order Type" = CONST(Production),
                                      "Order No." = FIELD("Order No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ToolTip = 'View the value entries of the item on the document or journal line.';
                    }
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintItemJnlLine(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        DeleteRecTemp;

                        PostingItemJnlFromProduction(false);

                        InsertTempRec;

                        SetFilterGroup;
                        CurrPage.Update(false);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        DeleteRecTemp;

                        PostingItemJnlFromProduction(true);

                        InsertTempRec;

                        SetFilterGroup;
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    ItemJnlLine: Record "Item Journal Line";
                begin
                    ItemJnlLine.Copy(Rec);
                    ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    ItemJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                    REPORT.RunModal(REPORT::"Inventory Movement", true, true, ItemJnlLine);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetActTimeAndQtyBase;

        ControlsMngt;
    end;

    trigger OnAfterGetRecord()
    begin
        ActualScrapQtyHideValue := false;
        ActualOutputQtyHideValue := false;
        ActualRunTimeHideValue := false;
        ActualSetupTimeHideValue := false;
        ActualConsumpQtyHideValue := false;
        ScrapQuantityHideValue := false;
        OutputQuantityHideValue := false;
        RunTimeHideValue := false;
        SetupTimeHideValue := false;
        QuantityHideValue := false;
        DescriptionIndent := 0;
        ShowShortcutDimCode(ShortcutDimCode);
        DescriptionOnFormat;
        QuantityOnFormat;
        SetupTimeOnFormat;
        RunTimeOnFormat;
        OutputQuantityOnFormat;
        ScrapQuantityOnFormat;
        ActualConsumpQtyOnFormat;
        ActualSetupTimeOnFormat;
        ActualRunTimeOnFormat;
        ActualOutputQtyOnFormat;
        ActualScrapQtyOnFormat;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ReserveItemJnlLine: Codeunit "Item Jnl. Line-Reserve";
    begin
        Commit();
        if not ReserveItemJnlLine.DeleteLineConfirm(Rec) then
            exit(false);
        ReserveItemJnlLine.DeleteLine(Rec);
    end;

    trigger OnInit()
    begin
        AppliesFromEntryEditable := true;
        QuantityEditable := true;
        OutputQuantityEditable := true;
        ScrapQuantityEditable := true;
        ScrapCodeEditable := true;
        FinishedEditable := true;
        WorkShiftCodeEditable := true;
        RunTimeEditable := true;
        SetupTimeEditable := true;
        CapUnitofMeasureCodeEditable := true;
        ConcurrentCapacityEditable := true;
        EndingTimeEditable := true;
        StartingTimeEditable := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        "Changed by User" := true;
    end;

    trigger OnOpenPage()
    begin
        SetFilterGroup;

        if ProdOrderLineNo <> 0 then
            ProdOrderLine.Get(ProdOrder.Status, ProdOrder."No.", ProdOrderLineNo);

        SetDimensionsVisibility;
    end;

    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        TempItemJrnlLine: Record "Item Journal Line" temporary;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        ReportPrint: Codeunit "Test Report-Print";
        UOMMgt: Codeunit "Unit of Measure Management";
        PostingDate: Date;
        xPostingDate: Date;
        ProdOrderLineNo: Integer;
        ShortcutDimCode: array[8] of Code[20];
        ToTemplateName: Code[10];
        ToBatchName: Code[10];
        ActualRunTime: Decimal;
        ActualSetupTime: Decimal;
        ActualOutputQty: Decimal;
        ActualScrapQty: Decimal;
        ActualConsumpQty: Decimal;
        FlushingFilter: Option Manual,Forward,Backward,"Pick + Forward","Pick + Backward","All Methods";
        [InDataSet]
        DescriptionIndent: Integer;
        [InDataSet]
        QuantityHideValue: Boolean;
        [InDataSet]
        SetupTimeHideValue: Boolean;
        [InDataSet]
        RunTimeHideValue: Boolean;
        [InDataSet]
        OutputQuantityHideValue: Boolean;
        [InDataSet]
        ScrapQuantityHideValue: Boolean;
        [InDataSet]
        ActualConsumpQtyHideValue: Boolean;
        [InDataSet]
        ActualSetupTimeHideValue: Boolean;
        [InDataSet]
        ActualRunTimeHideValue: Boolean;
        [InDataSet]
        ActualOutputQtyHideValue: Boolean;
        [InDataSet]
        ActualScrapQtyHideValue: Boolean;
        [InDataSet]
        StartingTimeEditable: Boolean;
        [InDataSet]
        EndingTimeEditable: Boolean;
        [InDataSet]
        ConcurrentCapacityEditable: Boolean;
        [InDataSet]
        CapUnitofMeasureCodeEditable: Boolean;
        [InDataSet]
        SetupTimeEditable: Boolean;
        [InDataSet]
        RunTimeEditable: Boolean;
        [InDataSet]
        WorkShiftCodeEditable: Boolean;
        [InDataSet]
        FinishedEditable: Boolean;
        [InDataSet]
        ScrapCodeEditable: Boolean;
        [InDataSet]
        ScrapQuantityEditable: Boolean;
        [InDataSet]
        OutputQuantityEditable: Boolean;
        [InDataSet]
        QuantityEditable: Boolean;
        [InDataSet]
        AppliesFromEntryEditable: Boolean;
        [InDataSet]
        DescriptionEmphasize: Text;
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    procedure Setup(TemplateName: Code[10]; BatchName: Code[10]; ProductionOrder: Record "Production Order"; ProdLineNo: Integer; PostDate: Date)
    begin
        ToTemplateName := TemplateName;
        ToBatchName := BatchName;
        ProdOrder := ProductionOrder;
        ProdOrderLineNo := ProdLineNo;
        PostingDate := PostDate;
        xPostingDate := PostingDate;

        FlushingFilter := FlushingFilter::Manual;
    end;

    local procedure GetActTimeAndQtyBase()
    begin
        ActualSetupTime := 0;
        ActualRunTime := 0;
        ActualOutputQty := 0;
        ActualScrapQty := 0;
        ActualConsumpQty := 0;

        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;
        if "Qty. per Cap. Unit of Measure" = 0 then
            "Qty. per Cap. Unit of Measure" := 1;

        if Item.Get("Item No.") then
            case "Entry Type" of
                "Entry Type"::Consumption:
                    if ProdOrderComp.Get(
                         ProdOrder.Status,
                         "Order No.",
                         "Order Line No.",
                         "Prod. Order Comp. Line No.")
                    then begin
                        ProdOrderComp.CalcFields("Act. Consumption (Qty)"); // Base Unit
                        ActualConsumpQty :=
                          ProdOrderComp."Act. Consumption (Qty)" / "Qty. per Unit of Measure";
                        if Item."Rounding Precision" > 0 then
                            ActualConsumpQty := UOMMgt.RoundToItemRndPrecision(ActualConsumpQty, Item."Rounding Precision")
                        else
                            ActualConsumpQty := Round(ActualConsumpQty, UOMMgt.QtyRndPrecision);
                    end;
                "Entry Type"::Output:
                    begin
                        if ProdOrderLineNo = 0 then
                            if not ProdOrderLine.Get(ProdOrder.Status, ProdOrder."No.", "Order Line No.") then
                                Clear(ProdOrderLine);
                        if ProdOrderLine."Prod. Order No." <> '' then begin
                            CostCalcMgt.CalcActTimeAndQtyBase(
                              ProdOrderLine, "Operation No.", ActualRunTime, ActualSetupTime, ActualOutputQty, ActualScrapQty);
                            ActualSetupTime :=
                              Round(ActualSetupTime / "Qty. per Cap. Unit of Measure", UOMMgt.TimeRndPrecision);
                            ActualRunTime :=
                              Round(ActualRunTime / "Qty. per Cap. Unit of Measure", UOMMgt.TimeRndPrecision);

                            ActualOutputQty := ActualOutputQty / "Qty. per Unit of Measure";
                            ActualScrapQty := ActualScrapQty / "Qty. per Unit of Measure";
                            if Item."Rounding Precision" > 0 then begin
                                ActualOutputQty := UOMMgt.RoundToItemRndPrecision(ActualOutputQty, Item."Rounding Precision");
                                ActualScrapQty := UOMMgt.RoundToItemRndPrecision(ActualScrapQty, Item."Rounding Precision");
                            end else begin
                                ActualOutputQty := Round(ActualOutputQty, UOMMgt.QtyRndPrecision);
                                ActualScrapQty := Round(ActualScrapQty, UOMMgt.QtyRndPrecision);
                            end;
                        end;
                    end;
            end;
    end;

    local procedure ControlsMngt()
    var
        OperationExist: Boolean;
    begin
        if ("Entry Type" = "Entry Type"::Output) and
           ("Operation No." <> '')
        then
            OperationExist := true
        else
            OperationExist := false;

        StartingTimeEditable := OperationExist;
        EndingTimeEditable := OperationExist;
        ConcurrentCapacityEditable := OperationExist;
        CapUnitofMeasureCodeEditable := OperationExist;
        SetupTimeEditable := OperationExist;
        RunTimeEditable := OperationExist;
        WorkShiftCodeEditable := OperationExist;

        FinishedEditable := "Entry Type" = "Entry Type"::Output;
        ScrapCodeEditable := "Entry Type" = "Entry Type"::Output;
        ScrapQuantityEditable := "Entry Type" = "Entry Type"::Output;
        OutputQuantityEditable := "Entry Type" = "Entry Type"::Output;

        QuantityEditable := "Entry Type" = "Entry Type"::Consumption;
        AppliesFromEntryEditable := "Entry Type" = "Entry Type"::Consumption;
    end;

    local procedure DeleteRecTemp()
    begin
        TempItemJrnlLine.DeleteAll();

        if Find('-') then
            repeat
                case "Entry Type" of
                    "Entry Type"::Consumption:
                        if "Quantity (Base)" = 0 then begin
                            TempItemJrnlLine := Rec;
                            TempItemJrnlLine.Insert();

                            Delete;
                        end;
                    "Entry Type"::Output:
                        if TimeIsEmpty and
                           ("Output Quantity (Base)" = 0) and ("Scrap Quantity (Base)" = 0)
                        then begin
                            TempItemJrnlLine := Rec;
                            TempItemJrnlLine.Insert();

                            Delete;
                        end;
                end;
            until Next = 0;
    end;

    local procedure InsertTempRec()
    begin
        if TempItemJrnlLine.Find('-') then
            repeat
                Rec := TempItemJrnlLine;
                "Changed by User" := false;
                Insert;
            until TempItemJrnlLine.Next = 0;
        TempItemJrnlLine.DeleteAll();
    end;

    procedure SetFilterGroup()
    begin
        FilterGroup(2);
        SetRange("Journal Template Name", ToTemplateName);
        SetRange("Journal Batch Name", ToBatchName);
        SetRange("Order Type", "Order Type"::Production);
        SetRange("Order No.", ProdOrder."No.");
        if ProdOrderLineNo <> 0 then
            SetRange("Order Line No.", ProdOrderLineNo);
        SetFlushingFilter;
        OnAfterSetFilterGroup(Rec, ProdOrder, ProdOrderLineNo);
        FilterGroup(0);
    end;

    procedure SetFlushingFilter()
    begin
        if FlushingFilter <> FlushingFilter::"All Methods" then
            SetRange("Flushing Method", FlushingFilter)
        else
            SetRange("Flushing Method");
    end;

    local procedure GetCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
        SourceTableName: Text[100];
        Descrip: Text[100];
    begin
        SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 5405);
        if ProdOrderLineNo <> 0 then
            Descrip := ProdOrderLine.Description
        else
            Descrip := ProdOrder.Description;

        exit(StrSubstNo('%1 %2 %3', SourceTableName, ProdOrder."No.", Descrip));
    end;

    local procedure PostingDateOnAfterValidate()
    begin
        if PostingDate = 0D then
            PostingDate := xPostingDate;

        if PostingDate <> xPostingDate then begin
            ModifyAll("Posting Date", PostingDate);
            xPostingDate := PostingDate;
            CurrPage.Update(false);
        end;
    end;

    local procedure FlushingFilterOnAfterValidate()
    begin
        SetFilterGroup;
        CurrPage.Update(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Level;
        if "Entry Type" = "Entry Type"::Output then
            DescriptionEmphasize := 'Strong'
        else
            DescriptionEmphasize := '';
    end;

    local procedure QuantityOnFormat()
    begin
        if "Entry Type" = "Entry Type"::Output then
            QuantityHideValue := true;
    end;

    local procedure SetupTimeOnFormat()
    begin
        if ("Entry Type" = "Entry Type"::Consumption) or
           ("Operation No." = '')
        then
            SetupTimeHideValue := true;
    end;

    local procedure RunTimeOnFormat()
    begin
        if ("Entry Type" = "Entry Type"::Consumption) or
           ("Operation No." = '')
        then
            RunTimeHideValue := true;
    end;

    local procedure OutputQuantityOnFormat()
    begin
        if "Entry Type" = "Entry Type"::Consumption then
            OutputQuantityHideValue := true;
    end;

    local procedure ScrapQuantityOnFormat()
    begin
        if "Entry Type" = "Entry Type"::Consumption then
            ScrapQuantityHideValue := true;
    end;

    local procedure ActualConsumpQtyOnFormat()
    begin
        if "Entry Type" = "Entry Type"::Output then
            ActualConsumpQtyHideValue := true;
    end;

    local procedure ActualSetupTimeOnFormat()
    begin
        if ("Entry Type" = "Entry Type"::Consumption) or
           ("Operation No." = '')
        then
            ActualSetupTimeHideValue := true;
    end;

    local procedure ActualRunTimeOnFormat()
    begin
        if ("Entry Type" = "Entry Type"::Consumption) or
           ("Operation No." = '')
        then
            ActualRunTimeHideValue := true;
    end;

    local procedure ActualOutputQtyOnFormat()
    begin
        if "Entry Type" = "Entry Type"::Consumption then
            ActualOutputQtyHideValue := true;
    end;

    local procedure ActualScrapQtyOnFormat()
    begin
        if "Entry Type" = "Entry Type"::Consumption then
            ActualScrapQtyHideValue := true;
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterGroup(var ItemJournalLine: Record "Item Journal Line"; ProductionOrder: Record "Production Order"; ProdOrderLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ItemJournalLine: Record "Item Journal Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;
}

