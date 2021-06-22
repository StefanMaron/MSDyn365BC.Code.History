codeunit 344 "County CaptionClass Mgmt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CountyTxt: Label 'County';

    [EventSubscriber(ObjectType::Codeunit, 42, 'OnResolveCaptionClass', '', true, true)]
    local procedure ResolveCaptionClass(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea = '5' then begin
            Caption := CountyClassTranslate(CaptionExpr);
            Resolved := true;
        end;
    end;

    local procedure CountyClassTranslate(CaptionExpr: Text): Text
    var
        CountryRegion: Record "Country/Region";
        CommaPosition: Integer;
        CountyCaptionType: Text[30];
        CountyCaptionRef: Text;
    begin
        CommaPosition := StrPos(CaptionExpr, ',');
        if CommaPosition > 0 then begin
            CountyCaptionType := CopyStr(CaptionExpr, 1, CommaPosition - 1);
            CountyCaptionRef := CopyStr(CaptionExpr, CommaPosition + 1);
            case CountyCaptionType of
                '1':
                    begin
                        if CountryRegion.Get(CountyCaptionRef) and (CountryRegion."County Name" <> '') then
                            exit(CountryRegion."County Name");
                        exit(CountyTxt);
                    end;
                else
                    exit(CountyTxt);
            end;
        end;
        exit(CountyTxt);
    end;
}

