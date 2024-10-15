namespace System.IO;

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
                field("Code"; Rec.Code)
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
                        Rec.EditNextTransformationRule();
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
                    field(Length; Rec.Length)
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
                    field("Table ID"; Rec."Table ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the ID of the table to get the record for the field lookup.';
                    }
                    field("Table Caption"; Rec."Table Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the table to get the record for the field lookup.';
                    }
                    field("Source Field ID"; Rec."Source Field ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the ID of the field to find the record for the field lookup.';
                    }
                    field("Source Field Caption"; Rec."Source Field Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the field to find the record for the field lookup.';
                    }
                    field("Target Field ID"; Rec."Target Field ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the ID of the field to get the value for the field lookup.';
                    }
                    field("Target Field Caption"; Rec."Target Field Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the field to get the value for the field lookup.';
                    }
                    field("Field Lookup Rule"; Rec."Field Lookup Rule")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of the field lookup. In case of Target the value from the Target Field ID will be taken as is, even if it is blank. In case of Original If Target Is Blank the original value will be taken if target one is blank.';
                    }
                }
                group(ExtractFromDate)
                {
                    Caption = 'Extract From Date';
                    Visible = ExtractFromDateVisibleExpr;
                    field("Extract From Date Type"; Rec."Extract From Date Type")
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
                            ResultText := Rec.TransformText(TestText);
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
          Rec."Transformation Type" in [Rec."Transformation Type"::Replace, Rec."Transformation Type"::"Regular Expression - Replace",
                                    Rec."Transformation Type"::"Regular Expression - Match"];
        ReplaceValueVisibleExpr :=
          Rec."Transformation Type" in [Rec."Transformation Type"::"Regular Expression - Replace", Rec."Transformation Type"::Replace];
        StartPositionVisibleExpr :=
          Rec."Transformation Type" in [Rec."Transformation Type"::Substring];
        LengthVisibleExpr :=
          Rec."Transformation Type" in [Rec."Transformation Type"::Substring];
        DateFormatVisibleExpr := Rec.IsDataFormatUpdateAllowed();
        LookupGroupVisibleExpr := Rec."Transformation Type" = Rec."Transformation Type"::"Field Lookup";
        RoundGroupVisibleExpr := Rec."Transformation Type" = Rec."Transformation Type"::Round;
        ExtractFromDateVisibleExpr := Rec."Transformation Type" = Rec."Transformation Type"::"Extract From Date";
    end;
}