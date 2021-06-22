codeunit 2021 "Image Analysis Result"
{

    trigger OnRun()
    begin
    end;

    var
        JSONManagement: Codeunit "JSON Management";
        Result: DotNet JObject;
        Tags: DotNet JArray;
        Color: DotNet JObject;
        DominantColors: DotNet JArray;
        Faces: DotNet JArray;
        LastAnalysisType: Option Tags,Faces,Color;

    procedure SetJson(JSONMgt: Codeunit "JSON Management"; AnalysisType: Option Tags,Faces,Color)
    begin
        Tags := Tags.JArray;
        Color := Color.JObject;
        DominantColors := DominantColors.JArray;
        Faces := Faces.JArray;

        LastAnalysisType := AnalysisType;

        JSONMgt.GetJSONObject(Result);
        if IsNull(Result) then
            exit;

        if not JSONManagement.GetArrayPropertyValueFromJObjectByName(Result, 'tags', Tags) then
            if not JSONManagement.GetArrayPropertyValueFromJObjectByName(Result, 'Predictions', Tags) then
                if not JSONManagement.GetArrayPropertyValueFromJObjectByName(Result, 'predictions', Tags) then
                    Tags := Tags.JArray;

        if not JSONManagement.GetArrayPropertyValueFromJObjectByName(Result, 'faces', Faces) then
            Faces := Faces.JArray;

        Color := Color.JObject;
        DominantColors := DominantColors.JArray;
        if JSONManagement.GetObjectPropertyValueFromJObjectByName(Result, 'color', Color) then
            JSONManagement.GetArrayPropertyValueFromJObjectByName(Color, 'dominantColors', DominantColors)
        else begin
            Color := Color.JObject;
            DominantColors := DominantColors.JArray;
        end;
    end;

    procedure TagCount(): Integer
    begin
        exit(Tags.Count);
    end;

    procedure TagName(Number: Integer): Text
    var
        Tag: DotNet JObject;
        Name: Text;
    begin
        JSONManagement.InitializeCollectionFromJArray(Tags);
        if JSONManagement.GetJObjectFromCollectionByIndex(Tag, Number - 1) then begin
            if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'name', Name) then
                if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'Tag', Name) then
                    JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'tagName', Name);
            exit(Name)
        end;
    end;

    procedure TagConfidence(Number: Integer): Decimal
    var
        Tag: DotNet JObject;
        Confidence: Decimal;
        ConfidenceText: Text;
    begin
        JSONManagement.InitializeCollectionFromJArray(Tags);
        if JSONManagement.GetJObjectFromCollectionByIndex(Tag, Number - 1) then begin
            if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'confidence', ConfidenceText) then
                if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'Probability', ConfidenceText) then
                    if not JSONManagement.GetStringPropertyValueFromJObjectByName(Tag, 'probability', ConfidenceText) then
                        ConfidenceText := '0';
            Evaluate(Confidence, ConfidenceText);
            exit(Confidence)
        end;
    end;

    procedure DominantColorForeground(): Text
    var
        ColorText: Text;
    begin
        JSONManagement.GetStringPropertyValueFromJObjectByName(Color, 'dominantColorForeground', ColorText);
        exit(ColorText);
    end;

    procedure DominantColorBackground(): Text
    var
        ColorText: Text;
    begin
        JSONManagement.GetStringPropertyValueFromJObjectByName(Color, 'dominantColorBackground', ColorText);
        exit(ColorText);
    end;

    procedure DominantColorCount(): Integer
    begin
        exit(DominantColors.Count);
    end;

    procedure DominantColor(Number: Integer): Text
    var
        DominantColor: DotNet JObject;
    begin
        JSONManagement.InitializeCollectionFromJArray(DominantColors);
        if JSONManagement.GetJObjectFromCollectionByIndex(DominantColor, Number - 1) then
            exit(Format(DominantColor));
    end;

    procedure FaceCount(): Integer
    begin
        exit(Faces.Count);
    end;

    procedure FaceAge(Number: Integer): Integer
    var
        Face: DotNet JObject;
        AgeText: Text;
        Age: Integer;
    begin
        JSONManagement.InitializeCollectionFromJArray(Faces);
        if JSONManagement.GetJObjectFromCollectionByIndex(Face, Number - 1) then begin
            JSONManagement.GetStringPropertyValueFromJObjectByName(Face, 'age', AgeText);
            Evaluate(Age, AgeText);
            if Age < 16 then
                exit(0);
            exit(Age);
        end;
    end;

    procedure FaceGender(Number: Integer): Text
    var
        Face: DotNet JObject;
        Gender: Text;
        AgeText: Text;
        Age: Integer;
    begin
        JSONManagement.InitializeCollectionFromJArray(Faces);
        if JSONManagement.GetJObjectFromCollectionByIndex(Face, Number - 1) then begin
            JSONManagement.GetStringPropertyValueFromJObjectByName(Face, 'age', AgeText);
            Evaluate(Age, AgeText);
            if Age < 16 then
                exit('');
            JSONManagement.GetStringPropertyValueFromJObjectByName(Face, 'gender', Gender);
            exit(Gender);
        end;
    end;

    procedure GetLatestAnalysisType(var AnalysisType: Option Tags,Faces,Color)
    begin
        AnalysisType := LastAnalysisType;
    end;
}

