@IsTest
public class UnsplashServiceTest {

    // =========================
    // MOCK для Unsplash API
    // =========================
    public class UnsplashMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // Мокируем JSON ответ Unsplash
            res.setBody('{"results":[{"urls":{"small":"https://example.com/test.jpg"}}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    // MOCK для ошибки HTTP
    public class UnsplashMockFail implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500); // эмулируем ошибку сервера
            return res;
        }
    }

    // =========================
    // Позитивный тест
    // =========================
    @IsTest
    static void testGetImageUrlValidQuery() {
        Test.setMock(HttpCalloutMock.class, new UnsplashMock());

        Test.startTest();
        String url = UnsplashService.getImageUrl('Apple');
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL не должен быть null');
        System.assertEquals('https://example.com/test.jpg', url, 'Должен вернуться мокированный URL');
    }

    // =========================
    // Негативный тест с пустым query
    // =========================
    @IsTest
    static void testGetImageUrlEmptyQuery() {
        Test.startTest();
        String url = UnsplashService.getImageUrl('');
        Test.stopTest();

        System.assertEquals(null, url, 'При пустом query метод должен возвращать null');
    }

    // =========================
    // Тест ошибки HTTP
    // =========================
    @IsTest
    static void testGetImageUrlHttpError() {
        Test.setMock(HttpCalloutMock.class, new UnsplashMockFail());

        Test.startTest();
        String url = UnsplashService.getImageUrl('Apple');
        Test.stopTest();

        System.assertEquals(null, url, 'При ошибке HTTP метод должен вернуть null');
    }
}
