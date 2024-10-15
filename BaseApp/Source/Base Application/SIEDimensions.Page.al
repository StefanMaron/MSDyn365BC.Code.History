page 11212 "SIE Dimensions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SIE Dimensions';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "SIE Dimension";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1070000)
            {
                ShowCaption = false;
                field("Dimension Code"; "Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Dimension CodeEditable";
                    ToolTip = 'Specifies a dimension code.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Editable = NameEditable;
                    ToolTip = 'Specifies a descriptive name for the dimension.';
                }
                field(Selected; Selected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this dimension should be used when importing or exporting G/L data.';
                }
                field("SIE Dimension"; "SIE Dimension")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "SIE DimensionEditable";
                    ToolTip = 'Specifies the number you want to assign to the dimension.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        "SIE DimensionEditable" := true;
        NameEditable := true;
        "Dimension CodeEditable" := true;
    end;

    trigger OnOpenPage()
    begin
        if CurrPage.LookupMode then begin
            "Dimension CodeEditable" := false;
            NameEditable := false;
            "SIE DimensionEditable" := false;
        end;
    end;

    var
        [InDataSet]
        "Dimension CodeEditable": Boolean;
        [InDataSet]
        NameEditable: Boolean;
        [InDataSet]
        "SIE DimensionEditable": Boolean;
}

