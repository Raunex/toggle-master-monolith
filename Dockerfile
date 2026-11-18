FROM python:3.9-slim@sha256:2d97f6910b16bd338d3060f261f53f144965f755599aab1acda1e13cf1731b1b

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

COPY wait_for_db.py app.py ./

EXPOSE 5000

ENTRYPOINT ["sh", "./entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]