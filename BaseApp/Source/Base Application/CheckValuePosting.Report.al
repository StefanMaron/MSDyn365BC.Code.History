report 30 "Check Value Posting"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CheckValuePosting.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Dimension Check Value Posting';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            PrintOnlyIfDetail = true;
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ValuePosting_DefaultDim1Caption; DefaultDim1.FieldCaption("Value Posting"))
            {
            }
            column(DimValueCode_DefaultDim1Caption; DefaultDim1.FieldCaption("Dimension Value Code"))
            {
            }
            column(DimensionCode_DefaultDim1Caption; DefaultDim1.FieldCaption("Dimension Code"))
            {
            }
            column(TableName_DefaultDim1Caption; DefaultDim1.FieldCaption("Table Caption"))
            {
            }
            column(TableID_DefaultDim1Caption; DefaultDim1.FieldCaption("Table ID"))
            {
            }
            column(AccountNoCaption; AccountNoCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CheckValuePostingCaption; CheckValuePostingCaptionLbl)
            {
            }
            dataitem(DefaultDim1; "Default Dimension")
            {
                DataItemTableView = SORTING("Table ID", "No.", "Dimension Code") WHERE("No." = FILTER(''));
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Dimension Code";
                column(DimensionCode_DefaultDim1; "Dimension Code")
                {
                }
                column(DimValueCode_DefaultDim1; "Dimension Value Code")
                {
                }
                column(ValuePosting_DefaultDim1; "Value Posting")
                {
                }
                column(TableName_DefaultDim1; "Table Caption")
                {
                }
                column(TableID_DefaultDim1; "Table ID")
                {
                }
                dataitem(DefaultDim2; "Default Dimension")
                {
                    DataItemLink = "Table ID" = FIELD("Table ID"), "Dimension Code" = FIELD("Dimension Code");
                    DataItemLinkReference = DefaultDim1;
                    DataItemTableView = SORTING("Table ID", "No.", "Dimension Code") WHERE("No." = FILTER(<> ''));
                    column(ValuePosting_DefaultDim2; "Value Posting")
                    {
                    }
                    column(DimValueCode_DefaultDim2; "Dimension Value Code")
                    {
                    }
                    column(DimensionCode_DefaultDim2; "Dimension Code")
                    {
                    }
                    column(No_DefaultDim2; "No.")
                    {
                    }
                    column(ErrorMessage_DefaultDim2; ErrorMessage)
                    {
                    }
                    column(ErrorCaption; ErrorCaptionLbl)
                    {
                    }
                    dataitem(DefaultDim3; "Default Dimension")
                    {
                        DataItemLink = "Dimension Code" = FIELD("Dimension Code");
                        DataItemLinkReference = DefaultDim1;
                        DataItemTableView = SORTING("Table ID", "No.", "Dimension Code");
                        column(ErrorMessage_DefaultDim3; ErrorMessage)
                        {
                        }
                        column(DimensionCode_DefaultDim3; "Dimension Code")
                        {
                        }
                        column(ValuePosting_DefaultDim3; "Value Posting")
                        {
                        }
                        column(DimValueCode_DefaultDim3; "Dimension Value Code")
                        {
                        }
                        column(TableID_DefaultDim3; "Table ID")
                        {
                        }
                        column(ErrorCaptionDefaultDim3; ErrorCaptionDefaultDim3Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ErrorMessage := '';

                            CheckAndMakeErrorMessage(DefaultDim1, DefaultDim3, ErrorMessage);

                            if ErrorMessage = '' then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            "Table Caption" := ObjectTransl.TranslateObject(ObjectTransl."Object Type"::Table, "Table ID");
                            if DefaultDim1."Table ID" = DATABASE::Customer then
                                if Cust.Get(DefaultDim2."No.") then begin
                                    SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
                                    SetRange("No.", Cust."Salesperson Code");
                                end;

                            if DefaultDim1."Table ID" = DATABASE::Vendor then
                                if Vend.Get(DefaultDim2."No.") then begin
                                    SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
                                    SetRange("No.", Vend."Purchaser Code");
                                end;

                            if (DefaultDim1."Table ID" <> DATABASE::Customer) and
                               (DefaultDim1."Table ID" <> DATABASE::Vendor)
                            then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(DefaultDim4; "Default Dimension")
                    {
                        DataItemLink = "Dimension Code" = FIELD("Dimension Code");
                        DataItemLinkReference = DefaultDim1;
                        DataItemTableView = SORTING("Table ID", "No.", "Dimension Code");
                        column(ErrorMessage_DefaultDim4; ErrorMessage)
                        {
                        }
                        column(TableName_DefaultDim4; "Table Caption")
                        {
                        }
                        column(DimensionCode_DefaultDim4; "Dimension Code")
                        {
                        }
                        column(DimValueCode_DefaultDim4; "Dimension Value Code")
                        {
                        }
                        column(ValuePosting_DefaultDim4; "Value Posting")
                        {
                        }
                        column(ErrorCaptionDefaultDim4; ErrorCaptionDefaultDim4Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ErrorMessage := '';

                            CheckAndMakeErrorMessage(DefaultDim1, DefaultDim4, ErrorMessage);

                            if ErrorMessage = '' then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            "Table Caption" := ObjectTransl.TranslateObject(ObjectTransl."Object Type"::Table, "Table ID");
                            if DefaultDim1."Table ID" = DATABASE::Customer then
                                if Cust.Get(DefaultDim2."No.") then begin
                                    SetRange("Table ID", DATABASE::"Responsibility Center");
                                    SetRange("No.", Cust."Responsibility Center");
                                end;

                            if DefaultDim1."Table ID" = DATABASE::Vendor then
                                if Vend.Get(DefaultDim2."No.") then begin
                                    SetRange("Table ID", DATABASE::"Responsibility Center");
                                    SetRange("No.", Vend."Responsibility Center");
                                end;

                            if (DefaultDim1."Table ID" <> DATABASE::Customer) and
                               (DefaultDim1."Table ID" <> DATABASE::Vendor)
                            then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        "Table Caption" := ObjectTransl.TranslateObject(ObjectTransl."Object Type"::Table, "Table ID");
                        ErrorMessage := '';

                        CheckAndMakeErrorMessage(DefaultDim1, DefaultDim2, ErrorMessage);

                        if ErrorMessage = '' then
                            CurrReport.Skip();
                    end;

                    trigger OnPostDataItem()
                    begin
                        CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    "Table Caption" := ObjectTransl.TranslateObject(ObjectTransl."Object Type"::Table, "Table ID");
                    DefaultDimBuffer."Table ID" := "Table ID";

                    if not DefaultDimBuffer.Find then
                        DefaultDimBuffer := DefaultDim1;
                end;

                trigger OnPostDataItem()
                begin
                    CurrReport.Break();
                end;
            }
            dataitem(DefaultDim5; "Default Dimension")
            {
                DataItemTableView = SORTING("Table ID", "No.", "Dimension Code") WHERE("Table ID" = FILTER(18 .. 23), "No." = FILTER(<> ''));
                PrintOnlyIfDetail = true;
                column(No_DefaultDim5; "No.")
                {
                }
                column(DimensionCode_DefaultDim5; "Dimension Code")
                {
                }
                column(DimValueCode_DefaultDim5; "Dimension Value Code")
                {
                }
                column(ValuePosting_DefaultDim5; "Value Posting")
                {
                }
                dataitem(DefaultDim6; "Default Dimension")
                {
                    DataItemLink = "Dimension Code" = FIELD("Dimension Code");
                    DataItemLinkReference = DefaultDim5;
                    DataItemTableView = SORTING("Table ID", "No.", "Dimension Code");
                    column(ErrorMessage_DefaultDim6; ErrorMessage)
                    {
                    }
                    column(TableName_DefaultDim6; "Table Caption")
                    {
                    }
                    column(DimensionCode_DefaultDim6; "Dimension Code")
                    {
                    }
                    column(DimValueCode_DefaultDim6; "Dimension Value Code")
                    {
                    }
                    column(ValuePosting_DefaultDim6; "Value Posting")
                    {
                    }
                    column(ErrorCaptionDefaultDim6; ErrorCaptionDefaultDim6Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ErrorMessage := '';

                        CheckAndMakeErrorMessage(DefaultDim5, DefaultDim6, ErrorMessage);

                        if ErrorMessage = '' then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        "Table Caption" := ObjectTransl.TranslateObject(ObjectTransl."Object Type"::Table, "Table ID");
                        if DefaultDim5."Table ID" = DATABASE::Customer then
                            if Cust.Get(DefaultDim5."No.") then begin
                                SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
                                SetRange("No.", Cust."Salesperson Code");
                            end;

                        if DefaultDim5."Table ID" = DATABASE::Vendor then
                            if Vend.Get(DefaultDim5."No.") then begin
                                SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
                                SetRange("No.", Vend."Purchaser Code");
                            end;
                    end;
                }
                dataitem(DefaultDim7; "Default Dimension")
                {
                    DataItemLink = "Dimension Code" = FIELD("Dimension Code");
                    DataItemLinkReference = DefaultDim5;
                    DataItemTableView = SORTING("Table ID", "No.", "Dimension Code");
                    column(ErrorMessage_DefaultDim7; ErrorMessage)
                    {
                    }
                    column(TableName_DefaultDim7; "Table Caption")
                    {
                    }
                    column(DimensionCode_DefaultDim7; "Dimension Code")
                    {
                    }
                    column(DimValueCode_DefaultDim7; "Dimension Value Code")
                    {
                    }
                    column(ValuePosting_DefaultDim7; "Value Posting")
                    {
                    }
                    column(ErrorCaptionDefaultDim7; ErrorCaptionDefaultDim7Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ErrorMessage := '';

                        CheckAndMakeErrorMessage(DefaultDim5, DefaultDim7, ErrorMessage);

                        if ErrorMessage = '' then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        "Table Caption" := ObjectTransl.TranslateObject(ObjectTransl."Object Type"::Table, "Table ID");
                        if DefaultDim5."Table ID" = DATABASE::Customer then
                            if Cust.Get(DefaultDim5."No.") then begin
                                SetRange("Table ID", DATABASE::"Responsibility Center");
                                SetRange("No.", Cust."Responsibility Center");
                            end;

                        if DefaultDim5."Table ID" = DATABASE::Vendor then
                            if Vend.Get(DefaultDim5."No.") then begin
                                SetRange("Table ID", DATABASE::"Responsibility Center");
                                SetRange("No.", Vend."Responsibility Center");
                            end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    "Table Caption" := ObjectTransl.TranslateObject(ObjectTransl."Object Type"::Table, "Table ID");
                    DefaultDimBuffer."Table ID" := "Table ID";

                    if DefaultDimBuffer.Find then
                        CurrReport.Skip();
                end;

                trigger OnPostDataItem()
                begin
                    CurrReport.Break();
                end;
            }
            dataitem(DefaultDim8; "Default Dimension")
            {
                DataItemTableView = SORTING("Table ID", "No.", "Dimension Code") WHERE("Value Posting" = FILTER("No Code"));
                column(ErrorMessage_DefaultDim8; ErrorMessage)
                {
                }
                column(ValuePosting_DefaultDim8; "Value Posting")
                {
                }
                column(DimValueCode_DefaultDim8; "Dimension Value Code")
                {
                }
                column(DimensionCode_DefaultDim8; "Dimension Code")
                {
                }
                column(No_DefaultDim8; "No.")
                {
                }
                column(TableID_DefaultDim8; "Table ID")
                {
                }
                column(TableName_DefaultDim8; "Table Caption")
                {
                }
                column(ErrorCaptionDefaultDim8; ErrorCaptionDefaultDim8Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    "Table Caption" := ObjectTransl.TranslateObject(ObjectTransl."Object Type"::Table, "Table ID");
                    ErrorMessage := '';

                    if "Dimension Value Code" <> '' then
                        ErrorMessage :=
                          StrSubstNo(
                            Text000,
                            "Dimension Value Code",
                            FieldCaption("Dimension Value Code"),
                            FieldCaption("Value Posting"),
                            "Value Posting")
                    else
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    DefaultDim1.CopyFilter("Table ID", "Table ID");
                    DefaultDim1.CopyFilter("Dimension Code", "Dimension Code");
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text000: Label 'You must not use a "%1" %2 when %3 is "%4".';
        Text001: Label '%1 must be %2.';
        Text002: Label '%1 %2 is mandatory.';
        Text003: Label '%1 %2 must not be mentioned.';
        Text004: Label '%1 %2 must be %3.';
        Cust: Record Customer;
        Vend: Record Vendor;
        DefaultDimBuffer: Record "Default Dimension" temporary;
        ObjectTransl: Record "Object Translation";
        ErrorMessage: Text[250];
        AccountNoCaptionLbl: Label 'Account No.';
        CurrReportPageNoCaptionLbl: Label 'Page';
        CheckValuePostingCaptionLbl: Label 'Check Value Posting';
        ErrorCaptionLbl: Label 'Error';
        ErrorCaptionDefaultDim3Lbl: Label 'Error';
        ErrorCaptionDefaultDim4Lbl: Label 'Error';
        ErrorCaptionDefaultDim6Lbl: Label 'Error';
        ErrorCaptionDefaultDim7Lbl: Label 'Error';
        ErrorCaptionDefaultDim8Lbl: Label 'Error';

    local procedure CheckAndMakeErrorMessage(DefaultDim1: Record "Default Dimension"; DefaultDim2: Record "Default Dimension"; var ErrorMessage: Text[250])
    begin
        case DefaultDim1."Value Posting" of
            DefaultDim1."Value Posting"::" ":
                if (((DefaultDim2."Value Posting" = DefaultDim2."Value Posting"::"Same Code") and
                     (DefaultDim2."Dimension Value Code" = '')) or
                    (DefaultDim2."Value Posting" = DefaultDim2."Value Posting"::"No Code")) and
                   (DefaultDim2."Dimension Value Code" <> '')
                then
                    ErrorMessage :=
                      StrSubstNo(
                        Text001,
                        DefaultDim2.FieldCaption("Dimension Value Code"), DefaultDim1."Dimension Value Code");
            DefaultDim1."Value Posting"::"Code Mandatory":
                if (DefaultDim2."Value Posting" = DefaultDim2."Value Posting"::"No Code") or
                   ((DefaultDim2."Value Posting" = DefaultDim2."Value Posting"::"Same Code") and
                    (DefaultDim2."Dimension Value Code" = ''))
                then
                    ErrorMessage :=
                      StrSubstNo(
                        Text002,
                        DefaultDim1.FieldCaption("Dimension Code"), DefaultDim1."Dimension Code");
            DefaultDim1."Value Posting"::"Same Code":
                case DefaultDim2."Value Posting" of
                    DefaultDim2."Value Posting"::"Code Mandatory":
                        if DefaultDim1."Dimension Value Code" = '' then
                            ErrorMessage :=
                              StrSubstNo(
                                Text003,
                                DefaultDim1.FieldCaption("Dimension Code"), DefaultDim1."Dimension Code")
                        else
                            if (DefaultDim2."Dimension Value Code" <> '') and
                               (DefaultDim1."Dimension Value Code" <> DefaultDim2."Dimension Value Code")
                            then
                                ErrorMessage :=
                                  StrSubstNo(
                                    Text004,
                                    DefaultDim2.FieldCaption("Dimension Value Code"), DefaultDim2."Dimension Value Code",
                                    DefaultDim1."Dimension Value Code");
                    DefaultDim2."Value Posting"::"No Code":
                        if DefaultDim1."Dimension Value Code" <> '' then
                            ErrorMessage :=
                              StrSubstNo(
                                Text001,
                                DefaultDim1.FieldCaption("Dimension Value Code"), DefaultDim1."Dimension Value Code");
                    DefaultDim2."Value Posting"::"Same Code", DefaultDim2."Value Posting"::" ":
                        if DefaultDim1."Dimension Value Code" <> DefaultDim2."Dimension Value Code" then
                            if DefaultDim1."Dimension Value Code" = '' then
                                ErrorMessage :=
                                  StrSubstNo(
                                    Text003,
                                    DefaultDim1.FieldCaption("Dimension Code"), DefaultDim1."Dimension Code")
                            else
                                ErrorMessage :=
                                  StrSubstNo(
                                    Text004,
                                    DefaultDim2.FieldCaption("Dimension Value Code"),
                                    DefaultDim2."Dimension Value Code", DefaultDim1."Dimension Value Code");
                end;
            DefaultDim1."Value Posting"::"No Code":
                if DefaultDim2."Dimension Value Code" <> '' then
                    ErrorMessage :=
                      StrSubstNo(
                        Text003,
                        DefaultDim1.FieldCaption("Dimension Code"), DefaultDim1."Dimension Code");
        end;
    end;
}

