page 99000811 "Prod. BOM Where-Used"
{
    Caption = 'Prod. BOM Where-Used';
    DataCaptionExpression = SetCaption;
    PageType = Worksheet;
    SourceTable = "Where-Used Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CalculateDate; CalculateDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calculation Date';
                    ToolTip = 'Specifies the date for which you want to show the where-used lines.';

                    trigger OnValidate()
                    begin
                        CalculateDateOnAfterValidate;
                    end;
                }
                field(ShowLevel; ShowLevel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Levels';
                    OptionCaption = 'Single,Multi';
                    ToolTip = 'Specifies the level of detail for the where-used lines.';

                    trigger OnValidate()
                    begin
                        ShowLevelOnAfterValidate;
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the item that the base item or production BOM is assigned to.';
                }
                field("Version Code"; "Version Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version code of the production BOM that the item or production BOM component is assigned to.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the item to which the item or production BOM component is assigned.';
                }
                field("Quantity Needed"; "Quantity Needed")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quantity of the item or the production BOM component that is needed for the assigned item.';
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
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(WhereUsedMgt.FindRecord(Which, Rec));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(WhereUsedMgt.NextRecord(Steps, Rec));
    end;

    trigger OnOpenPage()
    begin
        BuildForm;
    end;

    var
        Item: Record Item;
        ProdBOM: Record "Production BOM Header";
        WhereUsedMgt: Codeunit "Where-Used Management";
        ShowLevel: Option Single,Multi;
        CalculateDate: Date;
        [InDataSet]
        DescriptionIndent: Integer;

    procedure SetProdBOM(NewProdBOM: Record "Production BOM Header"; NewCalcDate: Date)
    begin
        ProdBOM := NewProdBOM;
        CalculateDate := NewCalcDate;
    end;

    procedure SetItem(NewItem: Record Item; NewCalcDate: Date)
    begin
        Item := NewItem;
        CalculateDate := NewCalcDate;
    end;

    local procedure BuildForm()
    begin
        if ProdBOM."No." <> '' then
            WhereUsedMgt.WhereUsedFromProdBOM(ProdBOM, CalculateDate, ShowLevel = ShowLevel::Multi)
        else
            WhereUsedMgt.WhereUsedFromItem(Item, CalculateDate, ShowLevel = ShowLevel::Multi);
    end;

    procedure SetCaption(): Text
    begin
        if ProdBOM."No." <> '' then
            exit(ProdBOM."No." + ' ' + ProdBOM.Description);

        exit(Item."No." + ' ' + Item.Description);
    end;

    local procedure CalculateDateOnAfterValidate()
    begin
        BuildForm;
        CurrPage.Update(false);
    end;

    local procedure ShowLevelOnAfterValidate()
    begin
        BuildForm;
        CurrPage.Update(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := "Level Code" - 1;
    end;
}

