codeunit 3010801 QuoteMgt
{
    Permissions = TableData "Purchase Line" = rm,
                  TableData "Sales Shipment Line" = rm,
                  TableData "Sales Invoice Line" = rm,
                  TableData "Sales Cr.Memo Line" = rm,
                  TableData "Purch. Rcpt. Line" = rm,
                  TableData "Sales Header Archive" = rimd,
                  TableData "Sales Line Archive" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text008: Label 'Recalculate\\Quote line   #1### of #2###';
        Text010: Label 'There are more end-totals than begin-totals.';
        Text011: Label 'Total ';
        Text012: Label 'There must be the same number of being-totals as end-totals. \Missing: %1 end-total(s).';
        Text014: Label '%1 recalculated.';

    procedure ReCalc(SalesHeader: Record "Sales Header"; ShowMessage: Boolean)
    var
        SalesLine: Record "Sales Line";
        xSalesLine: Record "Sales Line";
        Window: Dialog;
        BeginTotalTxt: array[99] of Text[250];
        ActualLevel: Integer;
        ActualTitle: array[99] of Integer;
        ActualOutline: Code[20];
        ActualPosition: Integer;
        SubTotalNet: array[99] of Decimal;
        SubTotalGross: array[99] of Decimal;
        Counter: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReCalc(SalesHeader, ShowMessage, IsHandled);
        if IsHandled then
            exit;

        with SalesLine do begin
            // Init
            ActualLevel := 1;
            Clear(ActualTitle);
            Clear(ActualOutline);
            ActualPosition := 0;

            // Open Dialog
            Window.Open(Text008);
            Counter := 0;

            // Increment levels
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");

            Window.Update(2, Count);

            if FindSet then
                repeat
                    // Update dialog
                    Counter := Counter + 1;
                    Window.Update(1, Counter);

                    // Calc level, indent etc.
                    case Type of
                        Type::"Begin-Total":
                            begin
                                // Description
                                ActualTitle[ActualLevel] := ActualTitle[ActualLevel] + 1;
                                BeginTotalTxt[ActualLevel] := Description;

                                // Outline
                                CalcOutline(ActualLevel, ActualTitle, ActualOutline);

                                // Level
                                Level := ActualLevel;
                                ActualLevel := ActualLevel + 1;

                                // Recalc title
                                if ActualLevel > 1 then
                                    "Title No." := ActualTitle[ActualLevel - 1];

                                // Maybe set position to zero
                                // ActualPos := 0;

                                // SubTotal
                                SubTotalNet[ActualLevel] := 0;
                                SubTotalGross[ActualLevel] := 0;
                            end;
                        Type::"End-Total":
                            begin
                                // SubTotal
                                "Subtotal Net" := SubTotalNet[ActualLevel];
                                "Subtotal Gross" := SubTotalGross[ActualLevel];
                                if ActualLevel > 1 then begin
                                    SubTotalNet[ActualLevel - 1] :=
                                      SubTotalNet[ActualLevel - 1] + SubTotalNet[ActualLevel];
                                    SubTotalGross[ActualLevel - 1] :=
                                      SubTotalGross[ActualLevel - 1] + SubTotalGross[ActualLevel];
                                end;

                                // Recalc title
                                CalcTitle(ActualLevel, ActualTitle, "Title No.");

                                ActualTitle[ActualLevel] := 0;

                                // Level
                                ActualLevel := ActualLevel - 1;
                                Level := ActualLevel;
                                if ActualLevel = 0 then
                                    Error(Text010);

                                // Outline
                                CalcOutline(ActualLevel, ActualTitle, ActualOutline);

                                // Description
                                Description := Format(Text011 + BeginTotalTxt[ActualLevel], -MaxStrLen(Description));
                            end;
                        else
                            // SubTotal
                            if "Quote Variant" <> "Quote Variant"::Variant then begin
                                SubTotalNet[ActualLevel] := SubTotalNet[ActualLevel] + "Line Amount";
                                SubTotalGross[ActualLevel] := SubTotalGross[ActualLevel] + "Amount Including VAT";
                            end;

                            // Position
                            if HasTypeToFillMandatoryFields and ("No." <> '') then begin
                                ActualPosition := ActualPosition + 10;
                                Position := ActualPosition;
                            end;

                            // Level
                            if xSalesLine.Type = xSalesLine.Type::"End-Total" then
                                CalcOutline(ActualLevel - 1, ActualTitle, ActualOutline);
                            Level := ActualLevel;

                            // Recalc title
                            if ActualLevel > 1 then
                                "Title No." := ActualTitle[ActualLevel - 1];
                    end;

                    // Fields that do not depend of the type
                    Classification := ActualOutline;

                    // write
                    Modify;
                    xSalesLine := SalesLine;
                until Next = 0;

            // CHeck no of begin/end levels
            if ActualLevel > 1 then
                Error(Text012, ActualLevel - 1);

            // Close dialog
            Window.Close;
        end;

        if ShowMessage then
            Message(Text014, SalesHeader."Document Type");
    end;

    [Scope('OnPrem')]
    procedure CalcOutline(Level: Integer; Title: array[99] of Integer; var Outline: Code[20])
    var
        i: Integer;
    begin
        Outline := '';
        for i := 1 to Level do
            Outline := Outline + StrSubstNo('%1.', Title[i]);

        if Level > 1 then
            Outline := DelChr(Outline, '>', '.');
    end;

    [Scope('OnPrem')]
    procedure CalcTitle(Level: Integer; Title: array[99] of Integer; var TitleNo: Integer)
    begin
        if Level > 1 then
            TitleNo := Title[Level - 1];
    end;

    procedure RecalcPostedInvoice(SalesInvHeader: Record "Sales Invoice Header")
    var
        PostedInvLine: Record "Sales Invoice Line";
        xPostedInvLine: Record "Sales Invoice Line";
        Window: Dialog;
        BeginTotalTxt: array[99] of Text[250];
        ActualLevel: Integer;
        ActualTitle: array[99] of Integer;
        ActualOutline: Code[20];
        ActualPosition: Integer;
        SubTotalNet: array[99] of Decimal;
        SubTotalGross: array[99] of Decimal;
        Counter: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalcPostedInvoice(SalesInvHeader, IsHandled);
        if IsHandled then
            exit;

        with PostedInvLine do begin
            ActualLevel := 1;
            Clear(ActualTitle);
            Clear(ActualOutline);
            ActualPosition := 0;

            // Open Dialog
            Window.Open(Text008);
            Counter := 0;

            // Increment levels
            SetRange("Document No.", SalesInvHeader."No.");

            Window.Update(2, Count);

            if FindSet then
                repeat
                    // Update dialog
                    Counter := Counter + 1;
                    Window.Update(1, Counter);

                    // Calc level, indent etc.
                    case Type of
                        Type::"Begin-Total":
                            begin
                                // Description
                                ActualTitle[ActualLevel] := ActualTitle[ActualLevel] + 1;
                                BeginTotalTxt[ActualLevel] := Description;

                                // Outline
                                CalcOutline(ActualLevel, ActualTitle, ActualOutline);

                                // Level
                                "Quote-Level" := ActualLevel;
                                ActualLevel := ActualLevel + 1;

                                // Recalc title
                                if ActualLevel > 1 then
                                    "Title No." := ActualTitle[ActualLevel - 1];

                                // Maybe set position to zero
                                // ActualPos := 0;

                                // SubTotal
                                SubTotalNet[ActualLevel] := 0;
                                SubTotalGross[ActualLevel] := 0;
                            end;
                        Type::"End-Total":
                            begin
                                // SubTotal
                                "Subtotal net" := SubTotalNet[ActualLevel];
                                "Subtotal gross" := SubTotalGross[ActualLevel];
                                if ActualLevel > 1 then begin
                                    SubTotalNet[ActualLevel - 1] :=
                                      SubTotalNet[ActualLevel - 1] + SubTotalNet[ActualLevel];
                                    SubTotalGross[ActualLevel - 1] :=
                                      SubTotalGross[ActualLevel - 1] + SubTotalGross[ActualLevel];
                                end;

                                // Recalc title
                                CalcTitle(ActualLevel, ActualTitle, "Title No.");

                                ActualTitle[ActualLevel] := 0;

                                // Level
                                ActualLevel := ActualLevel - 1;
                                "Quote-Level" := ActualLevel;
                                if ActualLevel = 0 then
                                    Error(Text010);

                                // Outline
                                CalcOutline(ActualLevel, ActualTitle, ActualOutline);

                                // Description
                                Description := Format(Text011 + BeginTotalTxt[ActualLevel], -MaxStrLen(Description));
                            end;
                        else
                            // SubTotal
                            SubTotalNet[ActualLevel] := SubTotalNet[ActualLevel] + "Line Amount";
                            SubTotalGross[ActualLevel] := SubTotalGross[ActualLevel] + "Amount Including VAT";

                            // Position
                            if (Type in [Type::"G/L Account" .. Type::"Charge (Item)"]) and
                               ("No." <> '')
                            then begin
                                ActualPosition := ActualPosition + 10;
                                Position := ActualPosition;
                            end;

                            // Level
                            if xPostedInvLine.Type = xPostedInvLine.Type::"End-Total" then
                                CalcOutline(ActualLevel - 1, ActualTitle, ActualOutline);
                            "Quote-Level" := ActualLevel;

                            // Recalc title
                            if ActualLevel > 1 then
                                "Title No." := ActualTitle[ActualLevel - 1];
                    end;

                    // Fields that do not depend of the type
                    Classification := ActualOutline;

                    // write
                    Modify;
                    xPostedInvLine := PostedInvLine;
                until Next = 0;

            // CHeck no of begin/end levels
            if ActualLevel > 1 then
                Error(Text012, ActualLevel - 1);

            // Close dialog
            Window.Close;
        end;
    end;

    procedure RecalcPostedCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        PostedCredMemoLine: Record "Sales Cr.Memo Line";
        xPostedCredMemoLine: Record "Sales Cr.Memo Line";
        Window: Dialog;
        BeginTotalTxt: array[99] of Text[250];
        ActualLevel: Integer;
        ActualTitle: array[99] of Integer;
        ActualOutline: Code[20];
        ActualPosition: Integer;
        SubTotalNet: array[99] of Decimal;
        SubTotalGross: array[99] of Decimal;
        Counter: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalcPostedCreditMemo(SalesCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        with PostedCredMemoLine do begin
            ActualLevel := 1;
            Clear(ActualTitle);
            Clear(ActualOutline);
            ActualPosition := 0;

            // Open Dialog
            Window.Open(Text008);
            Counter := 0;

            // Increment levels
            SetRange("Document No.", SalesCrMemoHeader."No.");

            Window.Update(2, Count);

            // Increment levels
            SetRange("Document No.", SalesCrMemoHeader."No.");
            if FindSet then
                repeat
                    // Update dialog
                    Counter := Counter + 1;
                    Window.Update(1, Counter);

                    // Calc level, indent etc.
                    case Type of
                        Type::"Begin-Total":
                            begin
                                // Description
                                ActualTitle[ActualLevel] := ActualTitle[ActualLevel] + 1;
                                BeginTotalTxt[ActualLevel] := Description;

                                // Outline
                                CalcOutline(ActualLevel, ActualTitle, ActualOutline);

                                // Level
                                "Quote-Level" := ActualLevel;
                                ActualLevel := ActualLevel + 1;

                                // Recalc title
                                if ActualLevel > 1 then
                                    "Title No." := ActualTitle[ActualLevel - 1];

                                // SubTotal
                                SubTotalNet[ActualLevel] := 0;
                                SubTotalGross[ActualLevel] := 0;
                            end;
                        Type::"End-Total":
                            begin
                                // SubTotal
                                "Subtotal net" := SubTotalNet[ActualLevel];
                                "Subtotal gross" := SubTotalGross[ActualLevel];
                                if ActualLevel > 1 then begin
                                    SubTotalNet[ActualLevel - 1] :=
                                      SubTotalNet[ActualLevel - 1] + SubTotalNet[ActualLevel];
                                    SubTotalGross[ActualLevel - 1] :=
                                      SubTotalGross[ActualLevel - 1] + SubTotalGross[ActualLevel];
                                end;

                                // Recalc title
                                CalcTitle(ActualLevel, ActualTitle, "Title No.");

                                ActualTitle[ActualLevel] := 0;

                                // Level
                                ActualLevel := ActualLevel - 1;
                                "Quote-Level" := ActualLevel;
                                if ActualLevel = 0 then
                                    Error(Text010);

                                // Outline
                                CalcOutline(ActualLevel, ActualTitle, ActualOutline);

                                // Description
                                Description := Format(Text011 + BeginTotalTxt[ActualLevel], -MaxStrLen(Description));
                            end;
                        else
                            // SubTotal
                            SubTotalNet[ActualLevel] := SubTotalNet[ActualLevel] + Amount;
                            SubTotalGross[ActualLevel] := SubTotalGross[ActualLevel] + "Amount Including VAT";

                            // Position
                            if (Type in [Type::"G/L Account" .. Type::"Charge (Item)"]) and
                               ("No." <> '')
                            then begin
                                ActualPosition := ActualPosition + 10;
                                Position := ActualPosition;
                            end;

                            // Level
                            if xPostedCredMemoLine.Type = xPostedCredMemoLine.Type::"End-Total" then
                                CalcOutline(ActualLevel - 1, ActualTitle, ActualOutline);
                            "Quote-Level" := ActualLevel;

                            // Recalc title
                            if ActualLevel > 1 then
                                "Title No." := ActualTitle[ActualLevel - 1];
                    end;

                    // Fields that do not depend of the type
                    Classification := ActualOutline;

                    // write
                    Modify;
                    xPostedCredMemoLine := PostedCredMemoLine;
                until Next = 0;

            // CHeck no of begin/end levels
            if ActualLevel > 1 then
                Error(Text012, ActualLevel - 1);

            // Close dialog
            Window.Close;
        end;
    end;

    procedure RecalcDocOnPrinting(SalesHeader: Record "Sales Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalcDocOnPrinting(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get;
        if (SalesHeader."Document Type" in [SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order]) and
           SalesSetup."Automatic recalculate Quotes"
        then begin
            ReCalc(SalesHeader, false);
            Commit;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReCalc(var SalesHeader: Record "Sales Header"; ShowMessage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalcPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalcPostedCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalcDocOnPrinting(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

