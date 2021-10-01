page 479 "Dimension Set Entries"
{
    Caption = 'Dimension Set Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Dimension Set Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; "Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension.';
                }
                field("Dimension Name"; "Dimension Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the Dimension Code field.';
                    Visible = false;
                }
                field(DimensionValueCode; "Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value.';
                }
                field("Dimension Value Name"; "Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the Dimension Value Code field.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdDimSetGlblDimNo)
            {
                ApplicationArea = Dimensions;
                Caption = 'Update Shortcut Dimension No.';
                Promoted = true;
                PromotedCategory = Process;
                Image = ChangeDimensions;
                ToolTip = 'Fix incorrect settings for one or more global or shortcut dimensions.';
                Visible = UpdDimSetGlblDimNoVisible;

                trigger OnAction()
                begin
                    Report.Run(Report::"Update Dim. Set Glbl. Dim. No.");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        FormCaption: Text[250];

    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;

    procedure SetUpdDimSetGlblDimNoVisible()
    begin
        UpdDimSetGlblDimNoVisible := true;
    end;

    var
        UpdDimSetGlblDimNoVisible: Boolean;
}

