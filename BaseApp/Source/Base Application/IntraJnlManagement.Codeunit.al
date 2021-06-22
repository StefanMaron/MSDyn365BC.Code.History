codeunit 350 IntraJnlManagement
{
    Permissions = TableData "Intrastat Jnl. Template" = imd,
                  TableData "Intrastat Jnl. Batch" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'INTRASTAT';
        Text001: Label 'Intrastat Journal';
        Text002: Label 'DEFAULT';
        Text003: Label 'Default Journal';
        OpenFromBatch: Boolean;

    procedure TemplateSelection(PageID: Integer; var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var JnlSelected: Boolean)
    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        JnlSelected := true;

        IntraJnlTemplate.Reset();
        IntraJnlTemplate.SetRange("Page ID", PageID);

        case IntraJnlTemplate.Count of
            0:
                begin
                    IntraJnlTemplate.Init();
                    IntraJnlTemplate.Name := Text000;
                    IntraJnlTemplate.Description := Text001;
                    IntraJnlTemplate.Validate("Page ID");
                    IntraJnlTemplate.Insert();
                    Commit();
                end;
            1:
                IntraJnlTemplate.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, IntraJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            IntrastatJnlLine.FilterGroup(2);
            IntrastatJnlLine.SetRange("Journal Template Name", IntraJnlTemplate.Name);
            IntrastatJnlLine.FilterGroup(0);
            if OpenFromBatch then begin
                IntrastatJnlLine."Journal Template Name" := '';
                PAGE.Run(IntraJnlTemplate."Page ID", IntrastatJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        OpenFromBatch := true;
        IntraJnlTemplate.Get(IntrastatJnlBatch."Journal Template Name");
        IntraJnlTemplate.TestField("Page ID");
        IntrastatJnlBatch.TestField(Name);

        IntrastatJnlLine.FilterGroup := 2;
        IntrastatJnlLine.SetRange("Journal Template Name", IntraJnlTemplate.Name);
        IntrastatJnlLine.FilterGroup := 0;

        IntrastatJnlLine."Journal Template Name" := '';
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        PAGE.Run(IntraJnlTemplate."Page ID", IntrastatJnlLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        CheckTemplateName(IntrastatJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        IntrastatJnlLine.FilterGroup(2);
        IntrastatJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        IntrastatJnlLine.FilterGroup(0);
    end;

    procedure OpenJnlBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        JnlSelected: Boolean;
    begin
        if IntrastatJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        IntrastatJnlBatch.FilterGroup(2);
        if IntrastatJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            IntrastatJnlBatch.FilterGroup(0);
            exit;
        end;
        IntrastatJnlBatch.FilterGroup(0);

        if not IntrastatJnlBatch.Find('-') then begin
            if not IntraJnlTemplate.FindFirst then
                TemplateSelection(0, IntrastatJnlLine, JnlSelected);
            if IntraJnlTemplate.FindFirst then
                CheckTemplateName(IntraJnlTemplate.Name, IntrastatJnlBatch.Name);
        end;
        IntrastatJnlBatch.Find('-');
        JnlSelected := true;
        if IntrastatJnlBatch.GetFilter("Journal Template Name") <> '' then
            IntraJnlTemplate.SetRange(Name, IntrastatJnlBatch.GetFilter("Journal Template Name"));
        case IntraJnlTemplate.Count of
            1:
                IntraJnlTemplate.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, IntraJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        IntrastatJnlBatch.FilterGroup(0);
        IntrastatJnlBatch.SetRange("Journal Template Name", IntraJnlTemplate.Name);
        IntrastatJnlBatch.FilterGroup(2);
    end;

    local procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not IntrastatJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not IntrastatJnlBatch.FindFirst then begin
                IntraJnlTemplate.Get(CurrentJnlTemplateName);
                IntrastatJnlBatch.Init();
                IntrastatJnlBatch."Journal Template Name" := IntraJnlTemplate.Name;
                IntrastatJnlBatch.Name := Text002;
                IntrastatJnlBatch.Description := Text003;
                IntrastatJnlBatch.Insert();
                Commit();
            end;
            CurrentJnlBatchName := IntrastatJnlBatch.Name;
        end;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.Get(IntrastatJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine.FilterGroup(2);
        IntrastatJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        IntrastatJnlLine.FilterGroup(0);
        if IntrastatJnlLine.Find('-') then;
    end;

    procedure LookupName(CurrentJnlTemplateName: Code[10]; CurrentJnlBatchName: Code[10]; var EntrdJnlBatchName: Text[10]): Boolean
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
        IntrastatJnlBatch.Name := CurrentJnlBatchName;
        IntrastatJnlBatch.FilterGroup(2);
        IntrastatJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        IntrastatJnlBatch.FilterGroup(0);
        if PAGE.RunModal(0, IntrastatJnlBatch) <> ACTION::LookupOK then
            exit(false);

        EntrdJnlBatchName := IntrastatJnlBatch.Name;
        exit(true);
    end;

    procedure CalcStatisticalValue(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; LastIntrastatJnlLine: Record "Intrastat Jnl. Line"; var StatisticalValue: Decimal; var TotalStatisticalValue: Decimal; var ShowStatisticalValue: Boolean; var ShowTotalStatisticalValue: Boolean)
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line";
        TempIntrastatJnlLine2: Record "Intrastat Jnl. Line";
    begin
        TempIntrastatJnlLine.CopyFilters(IntrastatJnlLine);

        if TempIntrastatJnlLine.CalcSums("Statistical Value") then begin
            if IntrastatJnlLine."Line No." <> 0 then // 0 = New record
                TotalStatisticalValue := TempIntrastatJnlLine."Statistical Value"
            else
                TotalStatisticalValue := TempIntrastatJnlLine."Statistical Value" + LastIntrastatJnlLine."Statistical Value";

            ShowTotalStatisticalValue := true;
        end else
            ShowTotalStatisticalValue := false;

        if IntrastatJnlLine."Line No." <> 0 then begin // 0 = New record
            TempIntrastatJnlLine.SetFilter("Line No.", '<=%1', IntrastatJnlLine."Line No.");
            if TempIntrastatJnlLine.CalcSums("Statistical Value") then begin
                StatisticalValue := TempIntrastatJnlLine."Statistical Value";
                ShowStatisticalValue := true;
            end else
                ShowStatisticalValue := false;
        end else begin
            TempIntrastatJnlLine.SetFilter("Line No.", '<=%1', LastIntrastatJnlLine."Line No.");
            if TempIntrastatJnlLine.CalcSums("Statistical Value") then begin
                TempIntrastatJnlLine2.CopyFilters(IntrastatJnlLine);
                TempIntrastatJnlLine2 := LastIntrastatJnlLine;
                if TempIntrastatJnlLine2.Next <> 0 then begin
                    StatisticalValue := TempIntrastatJnlLine."Statistical Value";
                end else
                    StatisticalValue := TempIntrastatJnlLine."Statistical Value" + LastIntrastatJnlLine."Statistical Value";

                ShowStatisticalValue := true;
            end else
                ShowStatisticalValue := false;
        end;
    end;
}

