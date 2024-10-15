report 31062 "Tariff Number Import (XML)"
{
    // //CO4.20: Controling - Basic: Intrastat CZ modification;

    ApplicationArea = Basic, Suite;
    Caption = 'Tariff Number Import (XML)';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            var
                lcuDOMmgt: Codeunit "XML DOM Management";
                ldnRecords: DotNet XmlNodeList;
                ldnSourceRootElement: DotNet XmlElement;
                ldnSourceCurrElement: DotNet XmlElement;
                ldnSourceFieldElement: DotNet XmlElement;
                lisStream: InStream;
                lfiFile: File;
                lcoTariffNo: Code[10];
                lcoUOMCode: Code[10];
                ldaStartingDate: Date;
                ldaEndingDate: Date;
                lteDescription: Text[250];
                linRowNo: Integer;
                lteTempText: Text[1024];
                lteFullDescription: Text[250];
                lteFullDescriptionENG: Text[250];
                linRecords: Integer;
            begin
                lfiFile.Open(gteFileName);
                lfiFile.CreateInStream(lisStream);

                lcuDOMmgt.LoadXMLNodeFromInStream(lisStream, ldnSourceRootElement);
                ldnSourceCurrElement := ldnSourceRootElement;

                if lcuDOMmgt.FindNode(ldnSourceCurrElement, Node_data, ldnSourceCurrElement) then
                    if lcuDOMmgt.FindNodes(ldnSourceCurrElement, Node_radek, ldnRecords) then
                        for linRecords := 0 to ldnRecords.Count - 1 do begin
                            ldnSourceCurrElement := ldnRecords.ItemOf(linRecords);

                            if GuiAllowed then begin
                                linRowNo += 1;
                                gdiWindow.Update(1, linRowNo);
                            end;

                            // Read fields
                            Clear(lcoTariffNo);
                            if lcuDOMmgt.FindNode(ldnSourceCurrElement, Node_kn, ldnSourceFieldElement) then
                                if ldnSourceFieldElement.Value <> '' then
                                    lcoTariffNo := ldnSourceFieldElement.Value;

                            Clear(ldaStartingDate);
                            if lcuDOMmgt.FindNode(ldnSourceCurrElement, Node_od, ldnSourceFieldElement) then
                                if ldnSourceFieldElement.Value <> '' then
                                    ldaStartingDate := RFormatDa(ldnSourceFieldElement.Value);

                            Clear(ldaEndingDate);
                            if lcuDOMmgt.FindNode(ldnSourceCurrElement, Node_do, ldnSourceFieldElement) then
                                if ldnSourceFieldElement.Value <> '' then
                                    ldaEndingDate := RFormatDa(ldnSourceFieldElement.Value);

                            Clear(lteDescription);
                            Clear(lteFullDescription);
                            if lcuDOMmgt.FindNode(ldnSourceCurrElement, Node_popis, ldnSourceFieldElement) then
                                if ldnSourceFieldElement.Value <> '' then begin
                                    lteTempText := CopyStr(ldnSourceFieldElement.Value, 1, MaxStrLen(lteTempText));
                                    lteTempText := ConvertText(lteTempText);
                                    lteDescription := CopyStr(lteTempText, 1, MaxStrLen(lteDescription));
                                    lteFullDescription := CopyStr(lteTempText, 1, MaxStrLen(lteFullDescription));
                                end;

                            Clear(lteFullDescriptionENG);
                            if lcuDOMmgt.FindNode(ldnSourceCurrElement, Node_popisan, ldnSourceFieldElement) then
                                if ldnSourceFieldElement.Value <> '' then begin
                                    lteTempText := CopyStr(ldnSourceFieldElement.Value, 1, MaxStrLen(lteTempText));
                                    lteTempText := ConvertText(lteTempText);
                                    lteFullDescriptionENG := CopyStr(lteTempText, 1, MaxStrLen(lteFullDescriptionENG));
                                end;

                            Clear(lcoUOMCode);
                            if lcuDOMmgt.FindNode(ldnSourceCurrElement, Node_mj_i, ldnSourceFieldElement) then
                                if ldnSourceFieldElement.Value <> '' then
                                    lcoUOMCode := ldnSourceFieldElement.Value;

                            // Insert to temp record
                            if (lcoTariffNo <> '') and IsInReqPeriod(ldaStartingDate, ldaEndingDate) then begin
                                greTempTariffNumber.Init;
                                greTempTariffNumber."No." := lcoTariffNo;
                                if lteDescription <> '' then
                                    greTempTariffNumber.Description := CopyStr(lteDescription, 1, MaxStrLen(greTempTariffNumber.Description));
                                greTempTariffNumber."Supplem. Unit of Measure Code" := lcoUOMCode;
                                greTempTariffNumber."Full Name" := lteFullDescription;
                                greTempTariffNumber."Full Name ENG" := lteFullDescriptionENG;
                                greTempTariffNumber.Insert;
                            end;
                        end;

                if GuiAllowed then
                    gdiWindow.Update(1, '');
            end;

            trigger OnPostDataItem()
            var
                lreTariffNumber: Record "Tariff Number";
                lreUOM: Record "Unit of Measure";
                linRecNo: Integer;
                linRecCount: Integer;
                lreTUOM: Record "Unit of Measure" temporary;
            begin
                with greTempTariffNumber do begin
                    Reset;
                    linRecCount := Count;
                    if linRecCount = 0 then
                        Error(Text005Err);

                    // Delete all existing records
                    lreTariffNumber.Reset;
                    lreTariffNumber.DeleteAll;

                    // Insert new records
                    Find('-');
                    if lreUOM.FindSet(false, false) then begin
                        repeat
                            lreTUOM := lreUOM;
                            lreTUOM.Insert;
                        until lreUOM.Next = 0;
                    end;

                    repeat
                        if GuiAllowed then begin
                            linRecNo += 1;
                            gdiWindow.Update(2, Round(linRecNo / linRecCount * 10000, 1));
                        end;

                        lreTariffNumber.Init;
                        lreTariffNumber."No." := "No.";
                        lreTariffNumber.Description := Description;
                        lreTariffNumber."Full Name" := "Full Name";
                        lreTariffNumber."Full Name ENG" := "Full Name ENG";
                        if ("Supplem. Unit of Measure Code" <> '') and ("Supplem. Unit of Measure Code" <> Text_uomc) then begin
                            lreTariffNumber."Supplementary Units" := true;
                            lreTUOM.SetRange("Tariff Number UOM Code", "Supplem. Unit of Measure Code");
                            if lreTUOM.FindFirst then
                                lreTariffNumber."Supplem. Unit of Measure Code" := lreTUOM.Code;
                        end;
                        lreTariffNumber.Insert(true);
                    until Next = 0;
                end;

                if GuiAllowed then
                    gdiWindow.Close;

                Message(Text010Msg, linRecCount);
            end;

            trigger OnPreDataItem()
            begin
                if gteFileName = '' then
                    Error(Text001Err);
                if gdaValidToDate = 0D then
                    Error(Text002Err);

                if GuiAllowed then
                    gdiWindow.Open(Text000Txt);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(gteFileName; gteFileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the xml file name for tariff number import.';

                        trigger OnAssistEdit()
                        begin
                            // gteFileName := lcuCommDlgMgt.OpenFile('','',4,ltcText001,0);
                        end;
                    }
                    field(gdaValidToDate; gdaValidToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Valid-to Date';
                        ToolTip = 'Specifies valid to date';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        greTempTariffNumber: Record "Tariff Number" temporary;
        gdiWindow: Dialog;
        gteFileName: Text[1024];
        gdaValidToDate: Date;
        Text000Txt: Label 'Importing records #1############\Processing @2@@@@@@@@@@@@';
        Text001Err: Label 'You must enter file name!';
        Text002Err: Label 'You must enter Valid-to Date!';
        Text005Err: Label 'There is nothing to import!';
        Text010Msg: Label 'Import has been successfully completed. %1 records inserted.';
        Node_data: Label 'data';
        Node_radek: Label 'radek';
        Node_kn: Label 'kn';
        Node_od: Label 'od';
        Node_do: Label 'do';
        Node_popis: Label 'popis';
        Node_popisan: Label 'popisan';
        Node_mj_i: Label 'mj_i';
        Text_uomc: Label 'ZZZ';
        Text_swapsource1: Label '&lt;';
        Text_swapsource2: Label '&gt;';
        Text_swapsource3: Label '&amp;';
        Text_swapchar1: Label '<';
        Text_swapchar2: Label '>';
        Text_swapchar3: Label '&';

    local procedure IsInReqPeriod(ldaStartingDate: Date; ldaEndingDate: Date): Boolean
    begin
        exit(
          ((ldaStartingDate <= gdaValidToDate) or (ldaStartingDate = 0D)) and
          ((ldaEndingDate >= gdaValidToDate) or (ldaEndingDate = 0D)));
    end;

    [Scope('OnPrem')]
    procedure ConvertText(lteText: Text[1024]) lteRet: Text[1024]
    begin
        SwapText(lteText, Text_swapsource1, Text_swapchar1);
        SwapText(lteText, Text_swapsource2, Text_swapchar2);
        SwapText(lteText, Text_swapsource3, Text_swapchar3);
        lteRet := lteText;
    end;

    local procedure SwapText(var lteSource: Text[1024]; lteOld: Text[250]; lteNew: Text[250])
    var
        linPosition: Integer;
    begin
        linPosition := StrPos(lteSource, lteOld);
        while linPosition <> 0 do begin
            lteSource := CopyStr(lteSource, 1, linPosition - 1) + lteNew + CopyStr(lteSource, linPosition + StrLen(lteOld));
            linPosition := StrPos(lteSource, lteOld);
        end;
    end;

    [Scope('OnPrem')]
    procedure RFormatDa(lteInput: Text[30]) ldaOutput: Date
    var
        linYear: Integer;
        linMonth: Integer;
        linDay: Integer;
    begin
        if lteInput = '' then
            exit(0D);
        Evaluate(linYear, CopyStr(lteInput, 1, 4));
        Evaluate(linMonth, CopyStr(lteInput, 6, 2));
        Evaluate(linDay, CopyStr(lteInput, 9, 2));
        ldaOutput := DMY2Date(linDay, linMonth, linYear);
    end;
}

