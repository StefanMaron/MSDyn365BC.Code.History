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
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Transformation Type"; "Transformation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled
                    end;
                }
                field("Next Transformation Rule"; "Next Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transformation rule that takes the result of this rule and transforms the value.';

                    trigger OnAssistEdit()
                    begin
                        EditNextTransformationRule;
                    end;
                }
                group(Control19)
                {
                    ShowCaption = false;
                    Visible = FindValueVisibleExpr;
                    field("Find Value"; "Find Value")
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
                    field("Replace Value"; "Replace Value")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                    }
                }
                group(Control21)
                {
                    ShowCaption = false;
                    Visible = StartPositionVisibleExpr;
                    field("Start Position"; "Start Position")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                    }
                    field("Starting Text"; "Starting Text")
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
                    field("Ending Text"; "Ending Text")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the last part of text that was imported from an external file to be transformed to a supported value by mapping to the specified field in Dynamics 365.';
                    }
                }
                group(Control23)
                {
                    ShowCaption = false;
                    Visible = DateFormatVisibleExpr;
                    field("Data Format"; "Data Format")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies in the Transformation Rule table the rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Microsoft Dynamics 365.';
                    }
                }
                group(Control24)
                {
                    ShowCaption = false;
                    Visible = DateFormatVisibleExpr;
                    field("Data Formatting Culture"; "Data Formatting Culture")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies in the Transformation Rule table the rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Microsoft Dynamics 365.';
                    }
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
        UpdateEnabled;
    end;

    var
        FindValueVisibleExpr: Boolean;
        ReplaceValueVisibleExpr: Boolean;
        StartPositionVisibleExpr: Boolean;
        LengthVisibleExpr: Boolean;
        DateFormatVisibleExpr: Boolean;
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
        DateFormatVisibleExpr := IsDataFormatUpdateAllowed;
    end;
}

