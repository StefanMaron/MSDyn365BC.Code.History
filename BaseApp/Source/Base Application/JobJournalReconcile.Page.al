page 376 "Job Journal Reconcile"
{
    Caption = 'Job Journal Reconcile';
    DataCaptionExpression = Caption;
    Editable = false;
    PageType = List;
    SourceTable = "Job Journal Quantity";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the job quantity to be reconciled.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FormatLine(Format("Unit of Measure Code"));
    end;

    trigger OnOpenPage()
    begin
        JobJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", Type, "No.", "Unit of Measure Code", "Work Type Code");
        if JobJnlLine.Find('-') then begin
            OldUnitOfMeasureCode := JobJnlLine."Unit of Measure Code";
            OldWorkTypeCode := JobJnlLine."Work Type Code";
            repeat
                if OldUnitOfMeasureCode <> JobJnlLine."Unit of Measure Code" then begin
                    InsertUnitOfMeasureQty;
                    InsertWorkTypeQty;
                end else
                    if OldWorkTypeCode <> JobJnlLine."Work Type Code" then
                        InsertWorkTypeQty;

                OldUnitOfMeasureCode := JobJnlLine."Unit of Measure Code";
                OldWorkTypeCode := JobJnlLine."Work Type Code";

                UnitOfMeasureQty := UnitOfMeasureQty + JobJnlLine.Quantity;
                WorkTypeQty := WorkTypeQty + JobJnlLine.Quantity;
                TotalQty := TotalQty + JobJnlLine.Quantity;
            until (JobJnlLine.Next = 0);

            InsertUnitOfMeasureQty;
            InsertWorkTypeQty;
            Init;
            "Is Total" := true;
            "Unit of Measure Code" := '';
            "Line Type" := "Line Type"::Total;
            "Work Type Code" := '';
            Quantity := TotalQty;
            Insert;

            TotalQty := 0;
        end;
    end;

    var
        Text000: Label 'Total %1';
        JobJnlLine: Record "Job Journal Line";
        UnitOfMeasureQty: Decimal;
        WorkTypeQty: Decimal;
        TotalQty: Decimal;
        OldUnitOfMeasureCode: Text[10];
        OldWorkTypeCode: Code[10];
        [InDataSet]
        Emphasize: Boolean;

    procedure SetJobJnlLine(var JobJnlLine2: Record "Job Journal Line")
    begin
        JobJnlLine2.TestField(Type, JobJnlLine2.Type::Resource);
        JobJnlLine.CopyFilters(JobJnlLine2);
        JobJnlLine.SetRange(Type, JobJnlLine2.Type::Resource);
        JobJnlLine.SetRange("No.", JobJnlLine2."No.");
    end;

    local procedure InsertUnitOfMeasureQty()
    begin
        Init;
        "Is Total" := false;
        "Unit of Measure Code" := OldUnitOfMeasureCode;
        "Line Type" := "Line Type"::Total;
        "Work Type Code" := '';
        Quantity := UnitOfMeasureQty;
        Insert;
        UnitOfMeasureQty := 0;
    end;

    local procedure InsertWorkTypeQty()
    begin
        Init;
        "Is Total" := false;
        "Unit of Measure Code" := OldUnitOfMeasureCode;
        "Line Type" := 0;
        "Work Type Code" := OldWorkTypeCode;
        Quantity := WorkTypeQty;
        Insert;
        WorkTypeQty := 0;
    end;

    procedure Caption(): Text
    var
        Res: Record Resource;
    begin
        Res.Get(JobJnlLine.GetRangeMin("No."));
        exit(Res."No." + ' ' + Res.Name);
    end;

    local procedure FormatLine(Text: Text[1024])
    begin
        if "Line Type" = "Line Type"::Total then begin
            Emphasize := true;
            Text := StrSubstNo(Text000, Text);
        end;
    end;
}

