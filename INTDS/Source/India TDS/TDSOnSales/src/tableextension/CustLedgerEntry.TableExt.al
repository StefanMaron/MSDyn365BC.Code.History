tableextension 18663 "Cust. Ledger Entry" extends "Cust. Ledger Entry"
{
    fields
    {
        field(18661; "Certificate No."; Code[20])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18662; "TDS Certificate Rcpt Date"; Date)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18663; "TDS Certificate Amount"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18664; "Financial Year"; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18665; "TDS Section Code"; Code[10])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "TDS Section";
        }
        field(18666; "Certificate Received"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
            begin
                if "Certificate Received" = FALSE then begin
                    "Certificate No." := '';
                    "TDS Certificate Rcpt Date" := 0D;
                    "TDS Certificate Amount" := 0;
                    "Financial Year" := 0;
                    "TDS Section Code" := '';
                end;
            end;
        }
        field(18667; "TDS Certificate Receivable"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                TDSCertUnCheckErr: Label 'Please uncheck TDS Certificate Received.';
            begin
                if "TDS Certificate Receivable" = FALSE then
                    if "TDS Certificate Received" = TRUE then
                        Error(TDSCertUnCheckErr);
            end;
        }
        field(18668; "TDS Certificate Received"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            trigger OnValidate()
            var
                TDSCertErr: Label 'TDS Certificate Received cannot be False unless TDS Receivable is False.';
            begin
                if "TDS Certificate Received" AND ("TDS Certificate Receivable" = FALSE) then
                    ERROR(TDSCertErr);

                if "TDS Certificate Received" = FALSE then begin
                    "Certificate No." := '';
                    "TDS Certificate Rcpt Date" := 0D;
                    "TDS Certificate Amount" := 0;
                    "Financial Year" := 0;
                    "TDS Section Code" := '';
                    "Certificate Received" := FALSE;
                end;
            end;
        }
    }
}