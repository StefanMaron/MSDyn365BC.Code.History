#if not CLEAN22
page 11212 "SIE Dimensions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SIE Dimensions';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "SIE Dimension";
    UsageCategory = Lists;
    ObsoleteReason = 'Replaced by Dimensions SIE page of the Standard Import Export (SIE) extension';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Control1070000)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Dimension CodeEditable";
                    ToolTip = 'Specifies a dimension code.';
                }
                field(Name; Rec.Name)
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
                field("SIE Dimension"; Rec."SIE Dimension")
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
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        if FeatureKeyManagement.IsSIEAuditFileExportEnabled() then begin
            Page.Run(5315); // page 5315 "Dimensions SIE"
            Error('');
        end;

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

#endif