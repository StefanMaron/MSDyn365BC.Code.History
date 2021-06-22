page 5847 "Average Cost Calc. Overview"
{
    Caption = 'Average Cost Calc. Overview';
    DataCaptionExpression = ItemName;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Average Cost Calc. Overview";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Attached to Valuation Date", "Attached to Entry No.", Type);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = TypeIndent;
                IndentationControls = Type;
                ShowAsTree = true;
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies either that the entry is a summary entry, Closing Entry, or the type that was used in the calculation of the average cost of the item.';
                }
                field("Valuation Date"; "Valuation Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the valuation date associated with the average cost calculation.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the item associated with the entry.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the location code associated with the entry.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(AverageCostCntrl; CalculateAverageCost)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 2;
                    Caption = 'Unit Cost';
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the average cost for this entry.';
                }
                field("Cost is Adjusted"; "Cost is Adjusted")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the cost is adjusted for the entry.';
                }
                field("Item Ledger Entry No."; "Item Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    HideValue = ItemLedgerEntryNoHideValue;
                    ToolTip = 'Specifies the number of the item ledger entry that this entry is linked to.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
                    Visible = false;
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    HideValue = EntryTypeHideValue;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that the average cost applies to.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number for the entry.';
                    Visible = false;
                }
                field("Document Line No."; "Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    HideValue = DocumentLineNoHideValue;
                    ToolTip = 'Specifies the document line that the comment applies to.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the quantity associated with the entry.';
                }
                field("Cost Amount (Expected)"; "Cost Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the expected cost in LCY of the quantity posting.';
                }
                field("Cost Amount (Actual)"; "Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the adjusted cost in LCY of the quantity posting.';
                }
            }
        }
    }

    actions
    {
        area(processing)
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
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        if ItemLedgEntry.Get("Entry No.") then
                            ItemLedgEntry.ShowDimensions;
                    end;
                }
                action("&Value Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Item Ledger Entry No." = FIELD("Item Ledger Entry No."),
                                  "Valuation Date" = FIELD("Valuation Date");
                    RunPageView = SORTING("Item Ledger Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    ToolTip = 'View the ledger entries that have been applied to this record.';

                    trigger OnAction()
                    var
                        ItemLedgEntry: Record "Item Ledger Entry";
                    begin
                        if ItemLedgEntry.Get("Item Ledger Entry No.") then
                            CODEUNIT.Run(CODEUNIT::"Show Applied Entries", ItemLedgEntry);
                    end;
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    var
                        ItemLedgEntry: Record "Item Ledger Entry";
                    begin
                        ItemLedgEntry.Get("Item Ledger Entry No.");
                        ItemLedgEntry.ShowReservationEntries(true);
                    end;
                }
            }
        }
        area(navigation)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentLineNoHideValue := false;
        EntryTypeHideValue := false;
        ItemLedgerEntryNoHideValue := false;
        TypeIndent := 0;
        SetExpansionStatus;
        if Type = Type::"Closing Entry" then begin
            Quantity := CalculateRemainingQty;
            "Cost Amount (Expected)" := CalculateCostAmt(false);
            "Cost Amount (Actual)" := CalculateCostAmt(true);
        end;
        TypeOnFormat;
        ItemLedgerEntryNoOnFormat;
        EntryTypeOnFormat;
        DocumentLineNoOnFormat;
    end;

    trigger OnOpenPage()
    begin
        InitTempTable;
        ExpandAll(AvgCostCalcOverview);

        SetRecFilters;
        CurrPage.Update(false);

        ItemName := StrSubstNo('%1  %2', Item."No.", Item.Description);
    end;

    var
        Item: Record Item;
        AvgCostCalcOverview: Record "Average Cost Calc. Overview" temporary;
        ItemLedgEntry: Record "Item Ledger Entry";
        GetAvgCostCalcOverview: Codeunit "Get Average Cost Calc Overview";
        Navigate: Page Navigate;
        ActualExpansionStatus: Integer;
        ItemName: Text[250];
        [InDataSet]
        TypeIndent: Integer;
        [InDataSet]
        ItemLedgerEntryNoHideValue: Boolean;
        [InDataSet]
        EntryTypeHideValue: Boolean;
        [InDataSet]
        DocumentLineNoHideValue: Boolean;

    procedure SetExpansionStatus()
    begin
        case true of
            IsExpanded(Rec):
                ActualExpansionStatus := 1;
            HasChildren(Rec):
                ActualExpansionStatus := 0
            else
                ActualExpansionStatus := 2;
        end;
    end;

    procedure InitTempTable()
    var
        AvgCostCalcOverviewFilters: Record "Average Cost Calc. Overview";
    begin
        AvgCostCalcOverview."Item No." := Item."No.";
        AvgCostCalcOverview.SetFilter("Valuation Date", Item.GetFilter("Date Filter"));
        AvgCostCalcOverview.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        AvgCostCalcOverview.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));

        GetAvgCostCalcOverview.Run(AvgCostCalcOverview);
        AvgCostCalcOverview.Reset();
        AvgCostCalcOverviewFilters.CopyFilters(Rec);
        Reset;
        DeleteAll();
        if AvgCostCalcOverview.Find('-') then
            repeat
                if AvgCostCalcOverview.Level = 0 then begin
                    Rec := AvgCostCalcOverview;
                    Insert;
                end;
            until AvgCostCalcOverview.Next = 0;
        CopyFilters(AvgCostCalcOverviewFilters);
    end;

    local procedure ExpandAll(var AvgCostCalcOverview: Record "Average Cost Calc. Overview")
    var
        AvgCostCalcOverviewFilters: Record "Average Cost Calc. Overview";
    begin
        AvgCostCalcOverview."Item No." := Item."No.";
        AvgCostCalcOverview.SetFilter("Valuation Date", Item.GetFilter("Date Filter"));
        AvgCostCalcOverview.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        AvgCostCalcOverview.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));

        GetAvgCostCalcOverview.Run(AvgCostCalcOverview);
        AvgCostCalcOverviewFilters.CopyFilters(Rec);
        Reset;
        DeleteAll();

        if AvgCostCalcOverview.Find('+') then
            repeat
                Rec := AvgCostCalcOverview;
                GetAvgCostCalcOverview.Calculate(AvgCostCalcOverview);
                AvgCostCalcOverview.Reset();
                AvgCostCalcOverview := Rec;
            until AvgCostCalcOverview.Next(-1) = 0;

        if AvgCostCalcOverview.Find('+') then
            repeat
                Rec := AvgCostCalcOverview;
                Insert;
            until AvgCostCalcOverview.Next(-1) = 0;

        CopyFilters(AvgCostCalcOverviewFilters);
    end;

    local procedure IsExpanded(ActualAvgCostCalcOverview: Record "Average Cost Calc. Overview"): Boolean
    var
        xAvgCostCalcOverview: Record "Average Cost Calc. Overview" temporary;
        Found: Boolean;
    begin
        xAvgCostCalcOverview := Rec;
        SetCurrentKey("Attached to Valuation Date", "Attached to Entry No.", Type);
        Rec := ActualAvgCostCalcOverview;
        Found := (Next(GetDirection) <> 0);
        if Found then
            Found := (Level > ActualAvgCostCalcOverview.Level);
        Rec := xAvgCostCalcOverview;
        exit(Found);
    end;

    local procedure HasChildren(var ActualAvgCostCalcOverview: Record "Average Cost Calc. Overview"): Boolean
    begin
        AvgCostCalcOverview := ActualAvgCostCalcOverview;
        if Type = Type::"Closing Entry" then
            exit(GetAvgCostCalcOverview.EntriesExist(AvgCostCalcOverview));
        exit(false);
    end;

    local procedure GetDirection(): Integer
    begin
        if Ascending then
            exit(1);
        exit(-1);
    end;

    procedure SetRecFilters()
    begin
        Reset;
        SetCurrentKey("Attached to Valuation Date", "Attached to Entry No.", Type);
        CurrPage.Update(false);
    end;

    procedure SetItem(var Item2: Record Item)
    begin
        Item.Copy(Item2);
    end;

    local procedure TypeOnFormat()
    begin
        if Type <> Type::"Closing Entry" then
            TypeIndent := 1;
    end;

    local procedure ItemLedgerEntryNoOnFormat()
    begin
        if Type = Type::"Closing Entry" then
            ItemLedgerEntryNoHideValue := true;
    end;

    local procedure EntryTypeOnFormat()
    begin
        if Type = Type::"Closing Entry" then
            EntryTypeHideValue := true;
    end;

    local procedure DocumentLineNoOnFormat()
    begin
        if Type = Type::"Closing Entry" then
            DocumentLineNoHideValue := true;
    end;
}

