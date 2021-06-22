page 484 "Edit Reclas. Dimensions"
{
    Caption = 'Edit Reclas. Dimensions';
    PageType = List;
    SourceTable = "Reclas. Dimension Set Buffer";
    SourceTableTemporary = true;

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
                    ToolTip = 'Specifies a dimension code to attach a dimension to a journal line.';
                }
                field("Dimension Name"; "Dimension Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the Dimension Code field.';
                    Visible = false;
                }
                field("Dimension Value Code"; "Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the original dimension value to register the transfer of items from the original dimension value to the new dimension value.';
                }
                field("New Dimension Value Code"; "New Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the new dimension value to register the transfer of items, from the original dimension value to the new dimension value.';
                }
                field("Dimension Value Name"; "Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the original Dimension Value Code field.';
                }
                field("New Dimension Value Name"; "New Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the New Dimension Value Code field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        FormCaption: Text[250];

    procedure GetDimensionIDs(var DimSetID: Integer; var NewDimSetId: Integer)
    begin
        DimSetID := GetDimSetID(Rec);
        NewDimSetId := GetNewDimSetID(Rec);
    end;

    procedure SetDimensionIDs(DimSetID: Integer; NewDimSetId: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        DeleteAll();
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet then
            repeat
                "Dimension Code" := DimSetEntry."Dimension Code";
                "Dimension Value Code" := DimSetEntry."Dimension Value Code";
                "Dimension Value ID" := DimSetEntry."Dimension Value ID";
                Insert;
            until DimSetEntry.Next = 0;
        DimSetEntry.SetRange("Dimension Set ID", NewDimSetId);
        if DimSetEntry.FindSet then
            repeat
                if not Get(DimSetEntry."Dimension Code") then begin
                    "Dimension Code" := DimSetEntry."Dimension Code";
                    "Dimension Value Code" := '';
                    "Dimension Value ID" := 0;
                    Insert;
                end;
                "New Dimension Value Code" := DimSetEntry."Dimension Value Code";
                "New Dimension Value ID" := DimSetEntry."Dimension Value ID";
                Modify;
            until DimSetEntry.Next = 0;
    end;

    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;
}

