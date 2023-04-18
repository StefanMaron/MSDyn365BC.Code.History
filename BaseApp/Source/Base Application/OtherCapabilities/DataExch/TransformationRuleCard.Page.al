page 1238 "Transformation Rule Card"
{
    Caption = 'Transformation Rule Card';
    PageType = Card;
    SourceTable = "Transformation Rule";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Transformation Type"; Rec."Transformation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Next Transformation Rule"; Rec."Next Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transformation rule that takes the result of this rule and transforms the value.';

                    trigger OnAssistEdit()
                    begin
                        EditNextTransformationRule();
                    end;
                }
                group(Control19)
                {
                    ShowCaption = false;
                    Visible = FindValueVisibleExpr;
                    field("Find Value"; Rec."Find Value")
                    {
                        ApplicationArea = Basic, Suite;
                        ShowMandatory = FindValueVisibleExpr;
                        ToolTip = 'Specifies in the Transformation Rule table the rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Microsoft Dynamics 365.';
                    }
                }
                group(Control20)
                {
                    ShowCaption = false;
                    Visible = ReplaceValueVisibleExpr;
                    field("Replace Value"; Rec."Replace Value")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                    }
                }
                group(Control21)
                {
                    ShowCaption = false;
                    Visible = StartPositionVisibleExpr;
                    field("Start Position"; Rec."Start Position")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                    }
                    field("Starting Text"; Rec."Starting Text")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the first part of text that was imported from an external file to be transformed to a supported value by mapping to the specified field in Dynamics 365.';
                    }
                }
                group(Control22)
                {
                    ShowCaption = false;
                    Visible = LengthVisibleExpr;
                    field(Length; Length)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the length of one item unit when measured in the specified unit of measure.';
                    }
                    field("Ending Text"; Rec."Ending Text")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the last part of text that was imported from an external file to be transformed to a supported value by mapping to the specified field in Dynamics 365.';
                    }
                }
                group(Control23)
                {
                    ShowCaption = false;
                    Visible = DateFormatVisibleExpr;
                    field("Data Format"; Rec."Data Format")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies in the Transformation Rule table the rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Microsoft Dynamics 365.';
                    }
                }
                group(Control24)
                {
                    ShowCaption = false;
                    Visible = DateFormatVisibleExpr;
                    field("Data Formatting Culture"; Rec."Data Formatting Culture")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies in the Transformation Rule table the rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Microsoft Dynamics 365.';
                    }
                }
                group(LookupGroup)
                {
                    Caption = 'Field Lookup Options';
                    Visible = LookupGroupVisibleExpr;
                    field("Table ID"; "Table ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the ID of the table to get the record for the field lookup.';
                    }
                    field("Table Caption"; "Table Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the table to get the record for the field lookup.';
                    }
                    field("Source Field ID"; "Source Field ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the ID of the field to find the record for the field lookup.';
                    }
                    field("Source Field Caption"; "Source Field Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the field to find the record for the field lookup.';
                    }
                    field("Target Field ID"; "Target Field ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the ID of the field to get the value for the field lookup.';
                    }
                    field("Target Field Caption"; "Target Field Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the field to get the value for the field lookup.';
                    }
                    field("Field Lookup Rule"; "Field Lookup Rule")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of the field lookup. In case of Target the value from the Target Field ID will be taken as is, even if it is blank. In case of Original If Target Is Blank the original value will be taken if target one is blank.';
                    }
                }
                group(ExtractFromDate)
                {
                    Caption = 'Extract From Date';
                    Visible = ExtractFromDateVisibleExpr;
                    field("Extract From Date Type"; "Extract From Date Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies what should be extracted from the date.';
                    }
                }
            }
            group(RoundGroup)
            {
                Caption = 'Round Options';
                Visible = RoundGroupVisibleExpr;
                field(Precision; Rec.Precision)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rounding precision.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rounding direction.';
                }
            }
            group(Test)
            {
                Caption = 'Test';
                field(TestText; TestText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Text';
                    MultiLine = true;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                }
                group(Control18)
                {
                    ShowCaption = false;
                    field(ResultText; ResultText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Result';
                        Editable = false;
                        ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                    }
                    field(UpdateResultLbl; UpdateResultLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            ResultText := TransformText(TestText);
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEnabled();
    end;

    var
        FindValueVisibleExpr: Boolean;
        ReplaceValueVisibleExpr: Boolean;
        StartPositionVisibleExpr: Boolean;
        LengthVisibleExpr: Boolean;
        DateFormatVisibleExpr: Boolean;
        LookupGroupVisibleExpr: Boolean;
        RoundGroupVisibleExpr: Boolean;
        ExtractFromDateVisibleExpr: Boolean;
        TestText: Text;
        ResultText: Text;
        UpdateResultLbl: Label 'Update';

    local procedure UpdateEnabled()
    begin
        FindValueVisibleExpr :=
          "Transformation Type" in ["Transformation Type"::Replace, "Transformation Type"::"Regular Expression - Replace",
                                    "Transformation Type"::"Regular Expression - Match"];
        ReplaceValueVisibleExpr :=
          "Transformation Type" in ["Transformation Type"::"Regular Expression - Replace", "Transformation Type"::Replace];
        StartPositionVisibleExpr :=
          "Transformation Type" in ["Transformation Type"::Substring];
        LengthVisibleExpr :=
          "Transformation Type" in ["Transformation Type"::Substring];
        DateFormatVisibleExpr := IsDataFormatUpdateAllowed();
        LookupGroupVisibleExpr := "Transformation Type" = "Transformation Type"::"Field Lookup";
        RoundGroupVisibleExpr := "Transformation Type" = "Transformation Type"::Round;
        ExtractFromDateVisibleExpr := "Transformation Type" = "Transformation Type"::"Extract From Date";
    end;
}