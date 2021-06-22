page 7133 "Item Budget Entries"
{
    ApplicationArea = ItemBudget;
    Caption = 'Item Budget Entries';
    DataCaptionExpression = GetCaption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Item Budget Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Budget Name"; "Budget Name")
                {
                    ApplicationArea = ItemBudget;
                    Editable = false;
                    ToolTip = 'Specifies the name of the item budget that the entry belongs to.';
                }
                field(Date; Date)
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the date of this item budget entry.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the number of the item that this budget entry applies to.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies a description of the budget figure.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the source type of this budget entry.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = GlobalDimension1CodeEnable;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = GlobalDimension1CodeVisible;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = GlobalDimension2CodeEnable;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = GlobalDimension2CodeVisible;
                }
                field("Budget Dimension 1 Code"; "Budget Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = BudgetDimension1CodeEnable;
                    ToolTip = 'Specifies the dimension value code for the Budget Dimension 1 code that this item budget entry is linked to.';
                    Visible = BudgetDimension1CodeVisible;
                }
                field("Budget Dimension 2 Code"; "Budget Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = BudgetDimension2CodeEnable;
                    ToolTip = 'Specifies the dimension value code for the Budget Dimension 2 code that this item budget entry is linked to.';
                    Visible = BudgetDimension2CodeVisible;
                }
                field("Budget Dimension 3 Code"; "Budget Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = BudgetDimension3CodeEnable;
                    ToolTip = 'Specifies the dimension value code for the Budget Dimension 3 Code that this item budget entry is linked to.';
                    Visible = BudgetDimension3CodeVisible;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that this item budget entry is linked to.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the quantity of this item budget entry.';
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the cost amount of this item budget entry.';
                }
                field("Sales Amount"; "Sales Amount")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the sales amount of this item budget line entry.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = ItemBudget;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
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
            group("<Action23>")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("<Action24>")
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if "Entry No." <> 0 then
            if "Dimension Set ID" <> xRec."Dimension Set ID" then
                LowestModifiedEntryNo := "Entry No.";
    end;

    trigger OnClosePage()
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    begin
        if LowestModifiedEntryNo < 2147483647 then
            UpdateItemAnalysisView.SetLastBudgetEntryNo(LowestModifiedEntryNo - 1);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if "Entry No." < LowestModifiedEntryNo then
            LowestModifiedEntryNo := "Entry No.";
        exit(true);
    end;

    trigger OnInit()
    begin
        BudgetDimension3CodeEnable := true;
        BudgetDimension2CodeEnable := true;
        BudgetDimension1CodeEnable := true;
        GlobalDimension2CodeEnable := true;
        GlobalDimension1CodeEnable := true;
        BudgetDimension3CodeVisible := true;
        BudgetDimension2CodeVisible := true;
        BudgetDimension1CodeVisible := true;
        GlobalDimension2CodeVisible := true;
        GlobalDimension1CodeVisible := true;
        LowestModifiedEntryNo := 2147483647;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if "Entry No." < LowestModifiedEntryNo then
            LowestModifiedEntryNo := "Entry No.";
        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Budget Name" := GetRangeMin("Budget Name");
        "Analysis Area" := GetRangeMin("Analysis Area");
        if (ItemBudgetName.Name <> "Budget Name") or (ItemBudgetName."Analysis Area" <> "Analysis Area") then
            ItemBudgetName.Get("Analysis Area", "Budget Name");
        if GetFilter("Item No.") <> '' then
            "Item No." := GetFirstItem(GetFilter("Item No."));
        Date := GetFirstDate(GetFilter(Date));
        "User ID" := UserId;

        if GetFilter("Global Dimension 1 Code") <> '' then
            "Global Dimension 1 Code" :=
              GetFirstDimValue(GLSetup."Global Dimension 1 Code", GetFilter("Global Dimension 1 Code"));

        if GetFilter("Global Dimension 2 Code") <> '' then
            "Global Dimension 2 Code" :=
              GetFirstDimValue(GLSetup."Global Dimension 2 Code", GetFilter("Global Dimension 2 Code"));

        if GetFilter("Budget Dimension 1 Code") <> '' then
            "Budget Dimension 1 Code" :=
              GetFirstDimValue(ItemBudgetName."Budget Dimension 1 Code", GetFilter("Budget Dimension 1 Code"));

        if GetFilter("Budget Dimension 2 Code") <> '' then
            "Budget Dimension 2 Code" :=
              GetFirstDimValue(ItemBudgetName."Budget Dimension 2 Code", GetFilter("Budget Dimension 2 Code"));

        if GetFilter("Budget Dimension 3 Code") <> '' then
            "Budget Dimension 3 Code" :=
              GetFirstDimValue(ItemBudgetName."Budget Dimension 3 Code", GetFilter("Budget Dimension 3 Code"));

        if GetFilter("Location Code") <> '' then
            "Location Code" := GetFirstLocationCode(GetFilter("Location Code"));
    end;

    trigger OnOpenPage()
    begin
        if GetFilter("Budget Name") = '' then
            ItemBudgetName.Init
        else begin
            CopyFilter("Analysis Area", ItemBudgetName."Analysis Area");
            CopyFilter("Budget Name", ItemBudgetName.Name);
            ItemBudgetName.FindFirst;
        end;
        CurrPage.Editable := not ItemBudgetName.Blocked;
        GLSetup.Get();
        GlobalDimension1CodeEnable := GLSetup."Global Dimension 1 Code" <> '';
        GlobalDimension2CodeEnable := GLSetup."Global Dimension 2 Code" <> '';
        BudgetDimension1CodeEnable := ItemBudgetName."Budget Dimension 1 Code" <> '';
        BudgetDimension2CodeEnable := ItemBudgetName."Budget Dimension 2 Code" <> '';
        BudgetDimension3CodeEnable := ItemBudgetName."Budget Dimension 3 Code" <> '';
        GlobalDimension1CodeVisible := GLSetup."Global Dimension 1 Code" <> '';
        GlobalDimension2CodeVisible := GLSetup."Global Dimension 2 Code" <> '';
        BudgetDimension1CodeVisible := ItemBudgetName."Budget Dimension 1 Code" <> '';
        BudgetDimension2CodeVisible := ItemBudgetName."Budget Dimension 2 Code" <> '';
        BudgetDimension3CodeVisible := ItemBudgetName."Budget Dimension 3 Code" <> '';
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemBudgetName: Record "Item Budget Name";
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        LowestModifiedEntryNo: Integer;
        [InDataSet]
        GlobalDimension1CodeVisible: Boolean;
        [InDataSet]
        GlobalDimension2CodeVisible: Boolean;
        [InDataSet]
        BudgetDimension1CodeVisible: Boolean;
        [InDataSet]
        BudgetDimension2CodeVisible: Boolean;
        [InDataSet]
        BudgetDimension3CodeVisible: Boolean;
        [InDataSet]
        GlobalDimension1CodeEnable: Boolean;
        [InDataSet]
        GlobalDimension2CodeEnable: Boolean;
        [InDataSet]
        BudgetDimension1CodeEnable: Boolean;
        [InDataSet]
        BudgetDimension2CodeEnable: Boolean;
        [InDataSet]
        BudgetDimension3CodeEnable: Boolean;

    local procedure GetFirstItem(ItemFilter: Text[250]): Code[20]
    var
        Item: Record Item;
    begin
        with Item do begin
            SetFilter("No.", ItemFilter);
            if FindFirst then
                exit("No.");

            exit('');
        end;
    end;

    local procedure GetFirstDate(DateFilter: Text[250]): Date
    var
        Period: Record Date;
    begin
        if DateFilter = '' then
            exit(0D);
        with Period do begin
            SetRange("Period Type", "Period Type"::Date);
            SetFilter("Period Start", DateFilter);
            if FindFirst then
                exit("Period Start");

            exit(0D);
        end;
    end;

    local procedure GetFirstDimValue(DimCode: Code[20]; DimValFilter: Text[250]): Code[20]
    var
        DimVal: Record "Dimension Value";
    begin
        if (DimCode = '') or (DimValFilter = '') then
            exit('');
        with DimVal do begin
            SetRange("Dimension Code", DimCode);
            SetFilter(Code, DimValFilter);
            if FindFirst then
                exit(Code);

            exit('');
        end;
    end;

    local procedure GetFirstLocationCode(LocationCodetFilter: Text[250]): Code[10]
    var
        Location: Record Location;
    begin
        with Location do begin
            SetFilter(Code, LocationCodetFilter);
            if FindFirst then
                exit(Code);

            exit('');
        end;
    end;
}

