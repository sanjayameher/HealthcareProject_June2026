import { useCallback, useEffect, useRef, useState } from 'react';

interface UseSpeechToTextOptions {
  onTranscript: (transcript: string, isFinal: boolean) => void;
  lang?: string;
}

export function useSpeechToText({ onTranscript, lang = 'en-US' }: UseSpeechToTextOptions) {
  const [isListening, setIsListening] = useState(false);
  const recognitionRef = useRef<SpeechRecognition | null>(null);
  const onTranscriptRef = useRef(onTranscript);
  onTranscriptRef.current = onTranscript;

  const RecognitionCtor =
    typeof window !== 'undefined' ? window.SpeechRecognition ?? window.webkitSpeechRecognition : undefined;
  const isSupported = Boolean(RecognitionCtor);

  const stopListening = useCallback(() => {
    recognitionRef.current?.stop();
  }, []);

  const startListening = useCallback(() => {
    if (!RecognitionCtor || recognitionRef.current) return;

    const recognition = new RecognitionCtor();
    recognition.lang = lang;
    recognition.continuous = true;
    recognition.interimResults = true;

    recognition.onresult = (event) => {
      let interimTranscript = '';
      for (let i = event.resultIndex; i < event.results.length; i++) {
        const result = event.results[i];
        if (result.isFinal) {
          onTranscriptRef.current(result[0].transcript, true);
        } else {
          interimTranscript += result[0].transcript;
        }
      }
      if (interimTranscript) {
        onTranscriptRef.current(interimTranscript, false);
      }
    };

    recognition.onerror = () => {
      recognitionRef.current = null;
      setIsListening(false);
    };

    recognition.onend = () => {
      recognitionRef.current = null;
      setIsListening(false);
    };

    recognition.start();
    recognitionRef.current = recognition;
    setIsListening(true);
  }, [RecognitionCtor, lang]);

  const toggleListening = useCallback(() => {
    if (isListening) {
      stopListening();
    } else {
      startListening();
    }
  }, [isListening, startListening, stopListening]);

  useEffect(() => {
    return () => recognitionRef.current?.stop();
  }, []);

  return { isListening, isSupported, toggleListening };
}
